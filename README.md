# Moimcity Terraform 

## Getting Started

### Install AWS CLI & Terraform

로컬에 AWS CLI 설치 [문서](https://docs.aws.amazon.com/ko_kr/cli/latest/userguide/getting-started-install.html)

```
brew install awscli
```
```
aws --version
# aws-cli/2.2.6 Python/3.8.8 Darwin/24.3.0 exe/x86_64 prompt/off
```

AWS IAM에서 생성한 `AWS Access Key ID`와 `AWS Secret Access Key` 등록. 리소스 생성에 필요한 권한이 있어야 합니다.

```
aws configure
# AWS Access Key ID [None] : 
# AWS Secret Access Key [None] : 
# Default region name [None] : ap-northeast-2
# Default output format [None] : 
```
```
cat ~/.aws/credentials 
# [default]
# aws_access_key_id = 
# aws_secret_access_key = 
```

Terraform의 설치는 아래와 같이 하시거나, 이 [문서](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)와 [다운로드 페이지](https://developer.hashicorp.com/terraform/install)를 확인하세요.

```
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

```

### Example: Create a parameter

AWS의 System Manager > Parameter Store를 관리하는 _example/ssm_ 폴더는 Terraform을 시작하는데 가장 쉬운 예제가 있습니다.

```
cd example/ssm
```

새로운 Parameter를 AWS에 등록하기 위해서 가장 먼저 해야 할 일은 `terraform.tfvars` 파일을 만들고 `variables.tf`에 정의된 변수들의 값을 입력하는 것입니다. `terraform.tfvars`파일은 gitignore 파일로 각자의 로컬에 새로 생성해야 합니다. 파일을 생성한 후 다음 값을 입력하세요.

```
aws_profile = "default"
aws_region  = "ap-northeast-2"
HELLO_WORLD = "hello world"
```

_main.tf_ 가 있는 _example/ssm_ 폴더로 이동후 아래 명령어를 실행하면 _.terrform_ 폴더를 생성하고 필요한 파일들을 설치합니다.

```
terrform init
```

만약 로컬에서 멀티 프로필을 관리하고 있고 _aws_profile_ 값이 `default`가 아니고 `tfstate`를 s3를 통해 관리하신다면 아래와 같은 명령어로 초기 설정 파일을 설치할 수 있습니다.

```
terraform init -backend-config "profile=default"
```

`main.tf` 파일이 AWS에 어떻게 반영되는지 확인하시려면 아래 명령어를 입력하세요. `+`기호는 생성될 리소스, `-`는 삭제될 리소스, 그리고 `~`기호는 변경될 리소스를 나타냅니다.

```
terraform plan -out plan
```

변경사항을 확인 후 실제 AWS에 반영하려면 아래 명령어를 입력하세요.

```
terraform apply "plan"
```

본 예제에서는 parameter를 추가하는 작업이므로 AWS 콘솔의 parameter store에서 `HELLO`라는 이름의 값으로 `hello world` 라는 파라미터가 생성되었는지 확인하실 수 있습니다.

해당 파라미터가 불필요한 경우 아래와 같은 명령어로 삭제할 때 영향받는 리소스는 없는지 확인할 수 있습니다.
```
terraform plan -destroy
```

실제로 삭제하려면 아래의 명령어를 입력하시고, AWS Parameter Store에서 삭제되었는지 확인합니다.
```
terraform destroy
```

## Directory structure

```
terraform/
├─ apps/ # 애플리케이션 레벨의 인프라 정의 및 관리
│  ├─ ecs-api-stage/ 
│  ├─ ecs-www-stage/ 
│  └─ ...
├─ modules/ # shared에 디펜던시가 있는 공용 모듈
│  ├─ ecs-fargate/ 
│  └─ ...
├─ shared/ # 공용 리소스
│  ├─ ec2/ 
│  ├─ iam/ 
│  ├─ ssm/ 
│  ├─ vpc/ 
│  └─ ...
└─ README.md
```

_shared_ 하위 각 디렉토리에 정의되어 있는 _main.tf_ 는 공용 리소스를 관리합니다. _modules_ 및 _apps_ 디렉토리에서 참조하는 리소스이므로 변경이 될 경우 _apps_ 디렉토리에도 최신 정보를 반영해야 합니다.

_apps_ 디렉토리에는 애플리케이션을 실행하기 위해 필요한 AWS 리소스들이 묶음으로 들어있습니다. ECS Fargate가 기본 인프라 구성이므로 이를 모듈화 하였고, 해당 모듈에서는 _target_group_, _alb_listener_, _route53_record_ 등을 한번에 실행합니다.

## Naming Rule

프로젝트명-앱이름-스테이지-리소스명-기타 방식으로 작성되었습니다.
eg. project-api-stage-ecs-cluster / project-public-sg / project-private1-rtb

## Sharing tfstate

본 프로젝트는 공동 작업을 위해서 terraform의 _state_ 를 S3에 저장합니다. 아래와 같이 선언하면 s3에 상태를 업로드하게 됩니다. 저장소는 아래와 같으며 `key`가 겹치지 않게 유의하시길 바랍니다.

```
terraform {
  backend "s3" {
    key    = "ec2.tfstate"
    bucket = "com.project.terraform"
    region = "ap-northeast-2"
  }
}
```
