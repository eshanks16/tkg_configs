load("@ytt:data", "data")
load("@ytt:assert", "assert")

TKGSProductName = "VMware Tanzu Kubernetes Grid Service for vSphere"
TKGProductName = "VMware Tanzu Kubernetes Grid"

def get_bom_data_for_k8s_version():
  for bom in data.values.boms:
    if bom.components.kubernetes.version == data.values.KUBERNETES_VERSION:
      return bom
    end
  end
  assert.fail("unable to get BoM file for the kubernetes version: " + data.values.KUBERNETES_VERSION)
end

def get_default_bom_data():
  for bom in data.values.boms:
    if bom.release.version == data.values.TKG_VERSION:
      return bom
    end
  end
  assert.fail("unable to get default BoM file for the TKG version: " + data.values.TKG_VERSION)
end

if data.values.PROVIDER_TYPE != "tkg-service-vsphere":
    bomDataK8sVersion = get_bom_data_for_k8s_version()
end

def kubeadm_image_repo(default_repo):
  if data.values.TKG_CUSTOM_IMAGE_REPOSITORY:
    return data.values.TKG_CUSTOM_IMAGE_REPOSITORY
  end

  # if downstream images are not available for Azure, change the kubeadm image repository to the staging repository name(global 'imageRepository' in BOM)
  if data.values.PROVIDER_TYPE == "azure":
    if hasattr(bomDataK8sVersion, 'azure') and hasattr(bomDataK8sVersion.azure, 'thirdPartyImage') and bomDataK8sVersion.azure.thirdPartyImage == True:
      return default_repo
    else:
      # when downstream image not available
      return bomDataK8sVersion.imageConfig.imageRepository
    end
  end

  return default_repo
end

bomData = get_default_bom_data()

def tkg_image_repo():
  return data.values.TKG_CUSTOM_IMAGE_REPOSITORY if data.values.TKG_CUSTOM_IMAGE_REPOSITORY else bomData.imageConfig.imageRepository
end

def tkg_image_repo_skip_tls_verify():
  return data.values.TKG_CUSTOM_IMAGE_REPOSITORY_SKIP_TLS_VERIFY == True and data.values.TKG_CUSTOM_IMAGE_REPOSITORY != ""
end

def tkg_image_repo_hostname():
  return tkg_image_repo().split("/")[0]
end

def get_provider():
  if data.values.PROVIDER_TYPE == "tkg-service-vsphere":
    return "vsphere"
  end
  return data.values.PROVIDER_TYPE
end

def get_kubernetes_provider():
  return TKGSProductName if data.values.PROVIDER_TYPE == "tkg-service-vsphere" else TKGProductName
end

def get_az_from_region(region, az, suffix):
  return az if az != "" else region + suffix
end

def validate():
  validate_funcs = [validate_oidc]
  for fn in validate_funcs:
    fn()
  end
  return True
end

def validate_oidc():
  if data.values.ENABLE_OIDC :
    data.values.OIDC_ISSUER_URL or assert.fail("oidc enabled, oidc issuer url should be provided")
    data.values.OIDC_USERNAME_CLAIM or assert.fail("oidc enabled, oidc username claim should be provided")
    data.values.OIDC_GROUPS_CLAIM or assert.fail("oidc enabled, oidc groups claim should be provided")
    data.values.OIDC_DEX_CA or assert.fail("oidc enabled, oidc dex ca should be provided.")
  end
end

def get_azure_image(bomDataForK8sVersion):
  if not hasattr(bomDataForK8sVersion, 'azure'):
    fail("no image information in BOM")
  end

  sharedGallery = get_shared_gallery_image(bomDataForK8sVersion)
  if sharedGallery != None:
    return sharedGallery
  end

  marketplace = get_marketplace_image(bomDataForK8sVersion)
  if marketplace != None:
    return marketplace
  end

  fail("invalid image information in BOM")
end


def get_shared_gallery_image(bomDataForK8sVersion):
  keysRequired = ['resourceGroup', 'name', 'subscriptionID', 'gallery', 'version']
  keysFromBom = dir(bomDataForK8sVersion.azure)

  if set(keysRequired) == set(keysFromBom):
    sharedGallery = {
      "resourceGroup": bomDataForK8sVersion.azure.resourceGroup,
      "name": bomDataForK8sVersion.azure.name,
      "subscriptionID": bomDataForK8sVersion.azure.subscriptionID,
      "gallery": bomDataForK8sVersion.azure.gallery,
      "version": bomDataForK8sVersion.azure.version
    }
    return {
      "sharedGallery": sharedGallery
    }
  else:
    return None
  end
end

def get_marketplace_image(bomDataForK8sVersion):
  keysRequired = ['publisher', 'offer', 'sku', 'version', 'thirdPartyImage']
  keysFromBom = dir(bomDataForK8sVersion.azure)
  keysFromBom.append('thirdPartyImage')

  if set(keysRequired) == set(keysFromBom):
    marketplace = {
      "publisher": bomDataForK8sVersion.azure.publisher,
      "offer": bomDataForK8sVersion.azure.offer,
      "sku": bomDataForK8sVersion.azure.sku,
      "version": bomDataForK8sVersion.azure.version,
      "thirdPartyImage": False
    }

    if hasattr(bomDataForK8sVersion.azure, 'thirdPartyImage'):
      marketplace["thirdPartyImage"] = bomDataForK8sVersion.azure.thirdPartyImage
    end

    return {
      "marketplace": marketplace
    }
  else:
    return None
  end
end

