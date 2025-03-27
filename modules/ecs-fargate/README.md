# ECS Fargate Module for staging

이 모듈은 ALB와 연결하는 Fargate 클러스터를 생성합니다. 최초 생성되는 task-definition 이미지는 nginx로 `host_port` 및 `container_port`로 80을 지정시 브라우저에서 Nginx가 뜨는 것을 확인하실 수 있습니다. (다만, 애플리케이션의 실제 포트를 지정하지 않는 경우 task-definition을 덮어쓰더라도 포트 매칭이 되지 않으니 80 포트는 테스트 용도로만 사용하시길 권해드립니다.)

Github Action의 CI/CD 구성 시 task-definition을 변경 배포하여 앞서 만든 공간에 원하는 애플리케이션을 띄울 수 있습니다.

## Resources

생성되는 리소스는 아래와 같습니다.
* CloudWatch Log Group: `ecr_task_definition_container` 변수의 이름으로 생성
* Route53 Record: `route53_record` 변수 이름으로 생성하고 ALB와 연결
* EC2 Target Group: `target_group` 변수 이름으로 생성하고 ALB와 연결 
* ECR repository: `ecr_repository` 변수 이름으로 생성
* ECR lifecycle policy: latest 태그가 포함된 Docker Image 2개 유지
* ECS Task Definition: ECS Service 생성을 위해 초기 task-definition을 정의하며 `ecs_task_definition_family`와 `ecs_task_definition_container` 변수명으로 생성. 추후 Github Action으로 덮어쓰여짐
* ECS Cluster: `ecs_cluster` 변수명으로 생성
* ECS Service: `ecs_service` 변수명으로 생성
* ECS Service Autoscaling: 서비스의 CPU 혹은 Memory 사용률이 80%에 도달하면 최대 10개까지 추가 컨테이너 배포

## Example

```
module "example" {
  source = "../../modules/ecs-fargate-stage"

  project_name = "example"
  stage        = "stage"

  vpc_name                = "example_vpc"
  subnet_names            = "example-subnet-private*"
  route53_zone_name       = "example.com."
  route53_private_zone    = false
  elb_name                = "example-internet-facing"
  security_group_name     = ["example-private-*"]
  ecs_task_role_name      = "example-ecs-task-role"
  task_excution_role_name = "example-ecs-task-execution-role"

  route53_record                = "www.example.com"
  target_group                  = "example-www-stage-tg"
  ecs_service                   = "example-www-stage-service"
  ecs_cluster                   = "example-www-stage-cluster"
  ecs_task_definition_family    = "example-www-stage"
  ecs_task_definition_container = "example-www-stage"
  ecr_repository                = "example-www-stage"
  host_port                     = 80
  container_port                = 80
}

```
