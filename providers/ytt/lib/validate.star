load("@ytt:data", "data")
load("@ytt:assert", "assert")

required_variable_list_vsphere = [
  "VSPHERE_USERNAME",
  "VSPHERE_PASSWORD",
  "VSPHERE_SERVER",
  "VSPHERE_DATACENTER",
  "VSPHERE_RESOURCE_POOL",
  "VSPHERE_DATASTORE",
  "VSPHERE_FOLDER",
  "VSPHERE_SSH_AUTHORIZED_KEY"]

required_variable_list_aws = [
  "AWS_REGION",
  "AWS_SSH_KEY_NAME"]

required_variable_list_azure = [
  "AZURE_TENANT_ID",
  "AZURE_SUBSCRIPTION_ID",
  "AZURE_CLIENT_ID",
  "AZURE_CLIENT_SECRET",
  "AZURE_LOCATION",
  "AZURE_SSH_PUBLIC_KEY_B64"]

required_variable_list_tkgs = [
  "CONTROL_PLANE_STORAGE_CLASS",
  "CONTROL_PLANE_VM_CLASS",
  "SERVICE_DOMAIN",
  "WORKER_STORAGE_CLASS",
  "WORKER_VM_CLASS"]

def validate_configuration(provider):
  if provider == "vsphere":
    flag_missing_variable_error(required_variable_list_vsphere)
  elif provider == "aws":
    flag_missing_variable_error(required_variable_list_aws)
  elif provider == "azure":
    flag_missing_variable_error(required_variable_list_azure)
  elif provider == "tkgs":
    flag_missing_variable_error(required_variable_list_tkgs)
  end
end

def flag_missing_variable_error(variables_list):
  missing_variable_str = ""
  for variable in variables_list:
    value = getattr(data.values, variable, None)
    if value == None or value == "":
      missing_variable_str = missing_variable_str + variable + ", "
    end
  end
  if missing_variable_str != "":
    assert.fail("missing configuration variables: " + missing_variable_str[:-2])
  end
end
