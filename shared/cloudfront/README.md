# CloudFront connected to Lambda Edge

CDN으로 사용할 CloudFront를 생성하고 Serverless를 통해 미리 배포된 Lambda Edge 함수를 연결합니다. 모든 Lambda 함수는 Serverless 프레임워크를 이용하니 해당 Git Repository를 확인하세요.

## Resources

* S3: CDN으로 이용할 S3 버킷 **com.example.cdn**
* S3 Policy: CloudFront의 접근을 허용하는 정책 생성
* CloudFront: 앞서 생성한 S3를 origin으로 갖는 CloudFront 생성, _/images/*_ 루트에 Lambda Edge 함수 연결, 대한민국 접근만 허용
* ACM: example.com 도메인에 대한 us-east-1 리전의 ssl 인증서
* Route53 Record: cdn.example.com을 생성하고 CloudFront 연결
