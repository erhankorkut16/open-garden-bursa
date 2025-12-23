# Open Garden Bursa - AWS S3 Kurulum Rehberi

## 📋 Gereksinimler

- AWS Hesabı
- AWS CLI yüklü ([İndirme linki](https://aws.amazon.com/cli/))
- GitHub hesabı
- Domain (opsiyonel)

## 🚀 Adım Adım Kurulum

### 1. AWS CLI Kurulumu ve Yapılandırması

```bash
# AWS CLI'yi yükleyin (macOS)
brew install awscli

# veya (Windows)
# AWS CLI installer'ı indirin ve çalıştırın

# AWS CLI'yi yapılandırın
aws configure
```

Girmeniz gerekenler:
```
AWS Access Key ID: [YOUR_ACCESS_KEY]
AWS Secret Access Key: [YOUR_SECRET_KEY]
Default region name: eu-central-1
Default output format: json
```

### 2. S3 Bucket Oluşturma

#### Option A: AWS Console Üzerinden

1. AWS Console'a giriş yapın
2. S3 servisine gidin
3. "Create bucket" butonuna tıklayın
4. Ayarlar:
   - **Bucket name**: `open-garden-bursa` (veya benzersiz bir isim)
   - **Region**: Europe (Frankfurt) eu-central-1
   - **Block Public Access**: Tüm seçenekleri kaldırın ✅
   - **Bucket Versioning**: Disabled
   - **Default encryption**: Disabled (veya istediğiniz gibi)
5. "Create bucket" tıklayın

#### Option B: AWS CLI ile

```bash
# Bucket oluştur
aws s3 mb s3://open-garden-bursa --region eu-central-1

# Public access ayarlarını kaldır
aws s3api put-public-access-block \
    --bucket open-garden-bursa \
    --public-access-block-configuration \
    "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"
```

### 3. Static Website Hosting Aktif Etme

#### AWS Console'dan:
1. Bucket'ınıza gidin
2. "Properties" sekmesine tıklayın
3. "Static website hosting" bölümünü bulun
4. "Edit" tıklayın
5. Ayarlar:
   - **Static website hosting**: Enable
   - **Index document**: `index.html`
   - **Error document**: `404.html`
6. "Save changes"

#### AWS CLI ile:
```bash
aws s3 website s3://open-garden-bursa \
    --index-document index.html \
    --error-document 404.html
```

### 4. Bucket Policy Ekleme

Public erişim için gerekli policy:

```bash
cat > bucket-policy.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::open-garden-bursa/*"
        }
    ]
}
EOF

# Policy'yi uygula
aws s3api put-bucket-policy \
    --bucket open-garden-bursa \
    --policy file://bucket-policy.json
```

### 5. İlk Deployment

```bash
# Projeyi klonlayın
git clone https://github.com/erhankorkut16/open-garden-bursa.git
cd open-garden-bursa

# Manuel deployment
./deploy.sh

# veya

# Environment variables ile
export S3_BUCKET_NAME=open-garden-bursa
export AWS_REGION=eu-central-1
./deploy.sh
```

### 6. GitHub Actions Kurulumu

GitHub repository'nizde Settings → Secrets and variables → Actions → New repository secret

Eklenecek secrets:

| Secret Name | Değer | Açıklama |
|------------|-------|----------|
| `AWS_ACCESS_KEY_ID` | AKIA... | AWS IAM kullanıcı access key |
| `AWS_SECRET_ACCESS_KEY` | wJa... | AWS IAM kullanıcı secret key |
| `AWS_REGION` | eu-central-1 | AWS region |
| `S3_BUCKET_NAME` | open-garden-bursa | S3 bucket adı |
| `CLOUDFRONT_DISTRIBUTION_ID` | E2... | (Opsiyonel) CloudFront ID |

**IAM Policy için gerekli izinler:**

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::open-garden-bursa",
                "arn:aws:s3:::open-garden-bursa/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "cloudfront:CreateInvalidation"
            ],
            "Resource": "*"
        }
    ]
}
```

### 7. CloudFront Kurulumu (Opsiyonel - SSL için)

#### Neden CloudFront?
- ✅ HTTPS desteği
- ✅ Daha hızlı yükleme (CDN)
- ✅ Custom domain desteği
- ✅ DDoS koruması

#### Kurulum:

1. **CloudFront Console'a gidin**
2. **"Create Distribution"** tıklayın
3. **Ayarlar:**

   **Origin Settings:**
   - Origin domain: `open-garden-bursa.s3-website.eu-central-1.amazonaws.com`
   - Protocol: HTTP only
   - Origin path: boş bırakın

   **Default Cache Behavior:**
   - Viewer protocol policy: **Redirect HTTP to HTTPS**
   - Allowed HTTP methods: GET, HEAD
   - Cache policy: CachingOptimized

   **Distribution Settings:**
   - Price class: Use all edge locations (best performance)
   - Alternate domain name (CNAME): `opengardenbursa.com`, `www.opengardenbursa.com`
   - Custom SSL certificate: **Request certificate** (ACM'den)
   - Default root object: `index.html`

4. **"Create distribution"**

#### SSL Certificate (ACM):

**ÖNEMLİ:** Certificate **us-east-1** region'ında olmalı!

```bash
# us-east-1'de certificate iste
aws acm request-certificate \
    --domain-name opengardenbursa.com \
    --subject-alternative-names www.opengardenbursa.com \
    --validation-method DNS \
    --region us-east-1
```

Veya AWS Console'dan:
1. **Certificate Manager** (us-east-1 region'ında)
2. **Request certificate**
3. Domain names: `opengardenbursa.com`, `*.opengardenbursa.com`
4. DNS validation seçin
5. Email'den gelen DNS record'ları domain'e ekleyin

### 8. Domain Bağlama

#### Route 53 ile:

```bash
# Hosted zone oluştur
aws route53 create-hosted-zone \
    --name opengardenbursa.com \
    --caller-reference $(date +%s)

# A record ekle (CloudFront için)
# Önce hosted-zone-id'yi alın
aws route53 list-hosted-zones

# Change batch oluştur
cat > change-batch.json << 'EOF'
{
    "Changes": [
        {
            "Action": "CREATE",
            "ResourceRecordSet": {
                "Name": "opengardenbursa.com",
                "Type": "A",
                "AliasTarget": {
                    "HostedZoneId": "Z2FDTNDATAQYW2",
                    "DNSName": "d123456789.cloudfront.net",
                    "EvaluateTargetHealth": false
                }
            }
        }
    ]
}
EOF

# Record'u ekle
aws route53 change-resource-record-sets \
    --hosted-zone-id YOUR_ZONE_ID \
    --change-batch file://change-batch.json
```

#### Cloudflare ile:

1. Domain'i Cloudflare'e ekleyin
2. DNS Records:
   - Type: `CNAME`
   - Name: `@`
   - Target: CloudFront distribution URL (örn: `d123456789.cloudfront.net`)
   - Proxy status: ✅ Proxied (turuncu bulut)

3. Domain registrar'ınızda:
   - Nameserver'ları Cloudflare'e yönlendirin

### 9. Test Etme

```bash
# S3 endpoint test
curl -I http://open-garden-bursa.s3-website.eu-central-1.amazonaws.com

# CloudFront test (varsa)
curl -I https://opengardenbursa.com

# SSL test
openssl s_client -connect opengardenbursa.com:443 -servername opengardenbursa.com
```

## 🔄 Günlük Kullanım

### Değişiklik Yapma:

```bash
# 1. Dosyaları düzenle
nano public/index.html

# 2. Git'e commit et
git add .
git commit -m "Update content"
git push origin main

# GitHub Actions otomatik deploy edecek!
```

### Manuel Deploy:

```bash
./deploy.sh
```

## 📊 Maliyet Tahmini

**S3 Maliyetleri (eu-central-1):**
- İlk 50 TB/ay: $0.023 per GB
- 1 GB veri + 10,000 request/ay: ~$0.50/ay

**CloudFront Maliyetleri:**
- İlk 10 TB/ay: $0.085 per GB
- 1 GB transfer + 10,000 request/ay: ~$1.00/ay

**Toplam tahmini:** $1.50-2.00/ay (düşük trafikli site için)

## 🐛 Sorun Giderme

### Site açılmıyor
```bash
# S3 bucket policy'yi kontrol et
aws s3api get-bucket-policy --bucket open-garden-bursa

# Static website hosting aktif mi?
aws s3api get-bucket-website --bucket open-garden-bursa

# Dosyalar yüklendi mi?
aws s3 ls s3://open-garden-bursa/
```

### CloudFront değişiklikleri göstermiyor
```bash
# Cache'i temizle
aws cloudfront create-invalidation \
    --distribution-id YOUR_DIST_ID \
    --paths "/*"
```

### GitHub Actions çalışmıyor
- Secrets'lerin doğru girildiğinden emin olun
- IAM user'ın gerekli izinleri olduğunu kontrol edin
- Actions sekmesinden error log'larını inceleyin

## 📚 Yararlı Komutlar

```bash
# Bucket içeriğini listele
aws s3 ls s3://open-garden-bursa/

# Tek bir dosyayı yükle
aws s3 cp public/index.html s3://open-garden-bursa/

# Bucket'ı tamamen sil (DİKKAT!)
aws s3 rb s3://open-garden-bursa --force

# CloudFront distributions listele
aws cloudfront list-distributions

# Bucket boyutunu hesapla
aws s3 ls s3://open-garden-bursa --recursive --summarize --human-readable
```

## 📞 Destek

Sorularınız için:
- GitHub Issues: [Open Issue](https://github.com/erhankorkut16/open-garden-bursa/issues)
- Email: erhan.korkut@runwex.com

---

**Son güncelleme:** Ocak 2025
