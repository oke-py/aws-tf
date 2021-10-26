provider "aws" {
  region = "us-east-1"
  alias  = "Virginia"
  default_tags {
    tags = {
      managed-by = "terraform"
      repo       = "github.com/oke-py/aws-tf"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
  alias  = "Tokyo"
  default_tags {
    tags = {
      managed-by = "terraform"
      repo       = "github.com/oke-py/aws-tf"
    }
  }
}
