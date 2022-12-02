import org.yaml.snakeyaml.Yaml

/*
 * Add default parameter values (a mapping) if they are not defined,
 * reading them from a YAML file
 */
def addDefaultParamValues(params, defaultsFile) {
  yaml = new Yaml()
  defaultValues = yaml.load(file(defaultsFile))

  defaultValues.each { name, value ->
    params[name] = evaluateWorkflowVars(getParamValue(params, name, value))
  }
}

/*
 * Evaluate workflow instrospection variables (workflow.*) inside a string
 */
def evaluateWorkflowVars(value) {
  matches = (value =~ /\$\{workflow\.[^}]*\}/).findAll()
  evaluated = value
  matches.each { m ->
    name = (m =~ /(?<=\{workflow\.).*(?=\})/).findAll()[0]
    evaluated = evaluated.replace(m, workflow[name].toString())
  }

  return evaluated
}

/*
 * Check if file exists of throw error
 */
def pathCheck(path, isDirectory = false) {
  f = file(path)
  if (!f.exists()) {
    throwError("Path ${path} does not exist")
  } else if (!f.isFile() && !isDirectory) {
    throwError("Path ${path} is not a file")
  } else if (!f.isDirectory() && isDirectory) {
    throwError("Path ${path} is not a directory")
  }

  return f
}

def isEmpty(params, name) {
  return !params.containsKey(name) || params[name] == null
}

def getParamValue(params, name, defaultValue) {
  return isEmpty(params, name) ? defaultValue : params[name]
}

def sanitizeFilename(filename) {
  return filename.toLowerCase().replaceAll(' ', '_').replaceAll('[^a-z0-9._-]', '')
}