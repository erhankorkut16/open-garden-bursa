# Open Garden Bursa - Website

Modern ve responsive düğün salonu web sitesi. AWS S3 + CloudFront üzerinde yayınlanmaktadır.

## 🚀 Özellikler

- ✨ Modern ve responsive tasarım
- 🎨 Gradient efektleri ve animasyonlar
- 📱 Mobil uyumlu
- ⚡ Hızlı yükleme
- 🔍 SEO optimize
- 📞 WhatsApp entegrasyonu
- 🎭 Smooth scroll ve fade-in animasyonlar

## 📦 Proje Yapısı

```
open-garden-bursa/
├── public/
│   └── index.html          # Ana sayfa
├── .github/
│   └── workflows/
│       └── deploy.yml      # GitHub Actions deployment
├── .gitignore
└── README.md
```

## 🛠️ Kurulum ve Deployment

### 1. AWS S3 Bucket Oluşturma

```bash
# S3 bucket oluştur
aws s3 mb s3://your-bucket-name --region eu-central-1

# Static website hosting'i aktif et
aws s3 website s3://your-bucket-name --index-document index.html --error-document index.html

# Bucket policy ekle (public erişim için)
```

**Bucket Policy Örneği:**
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::your-bucket-name/*"
        }
    ]
}
```

### 2. CloudFront Distribution (Opsiyonel - SSL için önerilir)

1. AWS Console'da CloudFront'a git
2. "Create Distribution" tıkla
3. Origin domain: S3 bucket endpoint'ini seç
4. Viewer protocol policy: "Redirect HTTP to HTTPS" seç
5. Alternate domain name (CNAME): kendi domain'inizi ekleyin
6. SSL Certificate: ACM'den certificate seçin veya oluşturun
7. Default root object: `index.html`
8. Create distribution

### 3. GitHub Secrets Ekleme

Repository Settings → Secrets and variables → Actions → New repository secret

Eklenecek secrets:
```
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_REGION=eu-central-1
S3_BUCKET_NAME=your-bucket-name
CLOUDFRONT_DISTRIBUTION_ID=your_distribution_id  # (Opsiyonel)
```

### 4. Deploy

```bash
# Değişiklikleri commit et
git add .
git commit -m "Update website"
git push origin main

# GitHub Actions otomatik olarak deploy edecek
```

## 🔧 Manuel Deploy

```bash
# AWS CLI kullanarak manuel deploy
aws s3 sync public/ s3://your-bucket-name/ --delete

# CloudFront cache'i temizle (varsa)
aws cloudfront create-invalidation --distribution-id YOUR_DIST_ID --paths "/*"
```

## 🌐 Domain Bağlama

### Route 53 ile (AWS)
1. Route 53'te hosted zone oluştur
2. A record oluştur ve CloudFront distribution'a yönlendir
3. Domain registrar'ınızda nameserver'ları Route 53'e yönlendir

### Cloudflare ile
1. Domain'i Cloudflare'e ekle
2. CNAME record oluştur: `@` → CloudFront distribution URL
3. SSL/TLS ayarını "Full" yap
4. Cloudflare nameserver'larını domain registrar'ınızda ayarla

## 📊 Performans Optimizasyonları

- ✅ CDN kullanımı (CloudFront)
- ✅ Lazy loading (görseller)
- ✅ Cache-Control headers
- ✅ Minified CSS/JS
- ✅ Responsive images
- ✅ Preconnect to external domains

## 🔒 Güvenlik

- HTTPS zorunlu (CloudFront ile)
- S3 bucket policy ile sadece gerekli erişim
- CORS ayarları
- Security headers (CloudFront Functions ile)

## 📝 Site Güncellemeleri

1. `public/index.html` dosyasını düzenle
2. Değişiklikleri commit et ve push et
3. GitHub Actions otomatik deploy edecek
4. CloudFront kullanıyorsanız cache 1-2 dakika içinde yenilenecek

## 🎨 Özelleştirme

### Renk Değişikenleri
```css
:root {
    --primary-color: #ff6b6b;
    --secondary-color: #4ecdc4;
    --accent-color: #45b7d1;
}
```

### İletişim Bilgileri
- Telefon: 0532 134 32 78
- Adres: Güneştepe, Recep Tayyip Erdoğan Blv NO: 40, 16160 Osmangazi/Bursa

## 📱 Sosyal Medya

- Facebook: [@opengarden](https://www.facebook.com/opengarden)
- Instagram: [@opengardenbursa](https://www.instagram.com/opengardenbursa)
- WhatsApp: +90 532 134 32 78

## 🐛 Sorun Giderme

### Deploy çalışmıyor
- GitHub Secrets'in doğru olduğundan emin ol
- AWS IAM user'ının S3 ve CloudFront yetkilerini kontrol et
- Actions sekmesinden hata loglarını incele

### Değişiklikler görünmüyor
- CloudFront cache'i temizle
- Browser cache'i temizle (Ctrl+Shift+R)
- S3 bucket'ta dosyaların güncellendiğini kontrol et

### SSL hatası
- CloudFront distribution'ın SSL certificate'ini kontrol et
- Certificate'in doğru region'da (us-east-1) olduğundan emin ol
- CNAME record'ların doğru olduğunu kontrol et

## 📄 Lisans

© 2025 Open Garden Bursa - Tüm hakları saklıdır.

## 🤝 Destek

Sorularınız için:
- 📧 Email: info@opengardenbursa.com
- 📞 Telefon: 0532 134 32 78
- 💬 WhatsApp: [Mesaj Gönder](https://wa.me/905321343278)

---

**Not:** Bu proje basit bir static website olduğu için Node.js veya build process gerektirmez. Sadece HTML, CSS ve vanilla JavaScript kullanır.
