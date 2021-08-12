

import yaml
import sys
import os
from pathlib import Path

YAML_SPLIT_STR = '---'
GATEKEEPER_NAMESPACE = 'gatekeeper-system'
GATEKEEPER_DEPLOYMENT = 'gatekeeper-controller-manager'

TARGET_NAMESPACE = 'kube-system'
PARAMERTIZED_IMAGE = '{{ .Values.gatekeeper.image.name }}:{{ .Values.gatekeeper.image.tag }}'
# If wanting an arg with no value, enter below as '<key>': None,. The code will parse the None value
CONTAINER_ARGS = {
  '--audit-interval': '{{ .Values.gatekeeper.args.auditIntervalSeconds }}',
  '--constraint-violations-limit': '{{ .Values.gatekeeper.args.constraintViolationsLimit }}',
  '--audit-from-cache': 'false',
  '--exempt-namespace': TARGET_NAMESPACE,
}
PARAMERTIZED_RESOURCE_LIMITS = {
  'limits': {
    'cpu': '{{ .Values.gatekeeper.resources.cpuLimit }}',
    'memory': '{{ .Values.gatekeeper.resources.memoryLimit }}',
  },
  'requests': {
    'cpu': '{{ .Values.gatekeeper.resources.cpuRequests }}',
    'memory': '{{ .Values.gatekeeper.resources.memoryRequests }}',
  },
}

class KubeYAML:
  def __init__(self, yaml_obj):
    self.yaml = yaml_obj
    self.deployment_container = ['spec', 'template', 'spec', 'containers', 0]

  def get_raw(self):
    return self.yaml

  # Allows get_nested_value to get values from slices
  # returns None if attempting to get a value from something other than a list or a dict
  def get_next_value(self, obj, key):
    if isinstance(obj, dict):
      return obj.get(key)
    if isinstance(obj, list) and isinstance(key, int) and key < len(obj) and key >= 0:
      return obj[key]
    else:
      return None

  # a method for safe extraction of nested values
  # if a key doesn't exist at any level, method returns None
  # otherwise returns the value specified by the given keys
  def get_nested_value(self, *keys):
    val = self.yaml
    for key in keys:
      val = self.get_next_value(val, key)
      if val == None:
        return None
    return val

  # a method for safe assignment of nested values
  # first n arguments are nested keys, final argument is value to set
  # creates a dictionary if none exists at given level
  # overwrites any primitive values with dictionarys
  def set_nested_value(self, *args):
    if (len(args) < 2):
      return
    val = self.yaml
    # Loope until the second to last nested key
    for key in args[:-2]:
      val = self.get_next_value(val, key)
      if val == None:
        val = {}
    # assign value (final arg) to final key
    val[args[-2]] = args[-1]

  # Get YAML values
  def get_kind(self):
    return self.get_nested_value('kind')
  def get_name(self):
    return self.get_nested_value('metadata','name')
  def get_container_args(self):
    return self.get_nested_value(*self.deployment_container, 'args')

  # Set YAML values (always check object exists before assigning)
  def set_container_args(self, new_args):
    self.set_nested_value(*self.deployment_container, 'args', new_args)
  def set_container_image(self, new_image):
    self.set_nested_value(*self.deployment_container, 'image', new_image)
  def set_resource_limits(self, new_limits):
    self.set_nested_value(*self.deployment_container, 'resources', new_limits)

  # Helper methods
  def update_container_args(self):
    # Use function to append args to safely manage args with None value
    def add_new_arg(key, value):
      if value == None:
        new_args.append(key)
        return
      new_args.append('='.join([key,value]))

    existing = self.get_container_args()
    if existing == None:
      existing = []

    new_args = []
    updated_args = set()
    for arg in existing:
      try:
        key, value = arg.split('=')
      except ValueError:
        key, value = [arg, None]

      if key in CONTAINER_ARGS:
        value = CONTAINER_ARGS[key]
        updated_args.add(key)
      add_new_arg(key, value)

    for key, value in CONTAINER_ARGS.items():
      if key not in updated_args:
        add_new_arg(key, value)

    self.set_container_args(new_args)

  def update_all_namespace_values(self, old_value, new_value):
    target_key = 'namespace'

    def update_namespace(node):
      for key, value in (node.items() if isinstance(node, dict) else
                      enumerate(node) if isinstance(node, list) else []):
        if key == target_key and value == old_value:
          node[key] = new_value
          return
        update_namespace(value)
    update_namespace(self.yaml)



def update_k8s_config(k8s_configs):
  # Use separate output obj to not mutate the list used to iterate over
  output_files = []

  for config in k8s_configs:
    if config.get_kind() == 'Namespace' and config.get_name() == GATEKEEPER_NAMESPACE:
      continue

    config.update_all_namespace_values(GATEKEEPER_NAMESPACE, TARGET_NAMESPACE)

    if config.get_kind() == 'Deployment' and config.get_name() == GATEKEEPER_DEPLOYMENT:
      config.update_container_args()
      config.set_container_image(PARAMERTIZED_IMAGE)
      config.set_resource_limits(PARAMERTIZED_RESOURCE_LIMITS)

    output_files.append(config)
  return output_files

def represent_str(self, data):
  style = None
  if data == '':
    style = '"'
  # Don't wrap quotes in tags
  elif '{{' in data and '}}' in data:
    style = ''
  else:
    resolvers = self.yaml_implicit_resolvers.get(data[0], [])
    for tag, regexp in resolvers:
        if regexp.match(data) and 'yaml' not in tag.split(':'):
            style = '"'
  return self.represent_scalar('tag:yaml.org,2002:str', data, style=style)

def update_gatekeeper_config(inFile, outFile):
  # Add custom representer to file
  yaml.add_representer(str, represent_str)

  # Read k8s config from yaml file
  k8s_configs = []
  with Path(inFile).open('r') as stream:
    try:
      for data in yaml.safe_load_all(stream):
        k8s_configs.append(KubeYAML(data))
    except yaml.YAMLError as exc:
      k8s_configs.append(KubeYAML({
        'error': 'Error Reading Yaml',
        'message': exc,
      }))
  # update yaml objects
  output_config = update_k8s_config(k8s_configs)

  # write result to output file
  out_objs = map(lambda k8syaml: k8syaml.get_raw(), output_config)
  with Path(outFile).open('w') as f:
    yaml.dump_all(out_objs, f, width=100)

if __name__ == "__main__":
  invalid = False
  try:
    inFile = sys.argv[1]
    outFile = sys.argv[2]
    if inFile == None or not os.path.isfile(inFile):
      invalid = True
      raise ValueError("Error: input argument should be a file")
    if outFile == None or not os.path.isfile(outFile):
      invalid = True
      raise ValueError("Error: output argument should be a file")
  except (IndexError, ValueError) as e:
    if isinstance(e, ValueError):
      print(e)
    invalid = True

  if invalid == True:
    raise IOError("Incorrect script usage.\nExpected usage:\n$ python " + sys.argv[0] + " <inputFile> <outputFile>")

  update_gatekeeper_config(inFile, outFile)
