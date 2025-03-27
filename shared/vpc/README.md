# VPC

![vpc](https://github.com/afrobambacar/terraform/blob/main/shared/vpc/vpc.png?raw=true)

## Resources

* VPC (1개)
* Internet Gateway (1개): VPC에 인바운드 트래픽을 받기 위한 장치
* NAT Gateway (1개): 프라이빗 서브넷에서 아웃바운드 트래픽을 처리하기 위한 장치
* Route Table (2개): 
  * Public: Internet Gateway에서 발생하는 인바운드 트래픽을 두개의 서브넷에 공급
  * Private: 프라이빗 서브넷에서 발생하는 트래픽을 허용하며 아웃바운드는 NAT Gateway를 이용합니다. 
* Subnet (4개): 서울리전의 가용공간 중 두 곳을 사용하며 각 가용공간은 퍼블릭과 프라이빗이 배치됩니다.
* S3 Endpoint: VPC에서 S3로 접근할 때 IG 혹은 NAT을 타지 않고 접속이 가능합니다.
