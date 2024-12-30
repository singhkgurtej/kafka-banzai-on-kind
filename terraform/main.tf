terraform {
  required_version = ">= 1.7.0"

  required_providers {
    flux = {
      source  = "fluxcd/flux"
      version = ">= 1.2"
    }
    github = {
      source  = "integrations/github"
      version = ">= 6.1"
    }
    kind = {
      source  = "tehcyx/kind"
      version = ">= 0.4"
    }
  }
}

# ==========================================
# Construct KinD cluster
# ==========================================

resource "kind_cluster" "default" {
    name           = "test-cluster"
    wait_for_ready = true

  kind_config {
      kind        = "Cluster"
      api_version = "kind.x-k8s.io/v1alpha4"
      node {
          role = "control-plane"
          kubeadm_config_patches = [
              "kind: InitConfiguration\nnodeRegistration:\n  kubeletExtraArgs:\n    node-labels: \"ingress-ready=true\"\n"
          ]
      }
      node {
          role = "worker"
      }
#       node {
#           role = "worker"
#       }
  }
}

# ==========================================
# Initialise a Github project
# ==========================================
#
resource "github_repository" "terraform-flux" {
  name        = var.github_repository
  description = var.github_repository
  visibility  = "private"
  auto_init   = true # This is extremely important as flux_bootstrap_git will not work without a repository that has been initialised
}

# ==========================================
# Bootstrap KinD cluster
# ==========================================

resource "flux_bootstrap_git" "this" {
  depends_on = [github_repository.terraform-flux]

  embedded_manifests = true
  path               = "flux/dev-cluster"
}


