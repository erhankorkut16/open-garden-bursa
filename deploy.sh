#!/bin/bash

# Open Garden Bursa - AWS S3 Deployment Script
# Bu script'i çalıştırmadan önce AWS CLI'yi yapılandırın: aws configure

set -e

# Renkli çıktı için
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Konfigürasyon
BUCKET_NAME="${S3_BUCKET_NAME:-open-garden-bursa}"
REGION="${AWS_REGION:-eu-central-1}"
CLOUDFRONT_ID="${CLOUDFRONT_DISTRIBUTION_ID:-}"

echo -e "${YELLOW}🚀 Open Garden Bursa - S3 Deployment Starting...${NC}\n"

# AWS CLI kontrolü
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI bulunamadı. Lütfen AWS CLI'yi yükleyin.${NC}"
    exit 1
fi

# AWS credentials kontrolü
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS credentials yapılandırılmamış. 'aws configure' komutunu çalıştırın.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ AWS CLI yapılandırması OK${NC}"

# Public klasörü kontrolü
if [ ! -d "public" ]; then
    echo -e "${RED}❌ 'public' klasörü bulunamadı.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Public klasörü bulundu${NC}\n"

# S3'e upload
echo -e "${YELLOW}📦 Dosyalar S3'e yükleniyor...${NC}"

# Tüm dosyaları sync et (HTML hariç)
aws s3 sync public/ s3://$BUCKET_NAME/ \
    --region $REGION \
    --delete \
    --cache-control "public, max-age=31536000" \
    --exclude "*.html" \
    --exclude "*.xml" \
    --exclude "*.txt"

# HTML, XML ve TXT dosyalarını daha kısa cache ile sync et
aws s3 sync public/ s3://$BUCKET_NAME/ \
    --region $REGION \
    --exclude "*" \
    --include "*.html" \
    --include "*.xml" \
    --include "*.txt" \
    --cache-control "public, max-age=3600" \
    --content-type "text/html; charset=utf-8"

echo -e "${GREEN}✓ Dosyalar başarıyla yüklendi${NC}\n"

# CloudFront invalidation (varsa)
if [ ! -z "$CLOUDFRONT_ID" ]; then
    echo -e "${YELLOW}🔄 CloudFront cache temizleniyor...${NC}"
    aws cloudfront create-invalidation \
        --distribution-id $CLOUDFRONT_ID \
        --paths "/*" > /dev/null
    echo -e "${GREEN}✓ CloudFront cache temizlendi${NC}\n"
else
    echo -e "${YELLOW}ℹ CloudFront distribution ID bulunamadı. Cache temizlenmedi.${NC}\n"
fi

# Bucket URL'i
BUCKET_URL="http://$BUCKET_NAME.s3-website.$REGION.amazonaws.com"

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Deployment tamamlandı!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
echo -e "${YELLOW}🌐 Site URL:${NC} $BUCKET_URL"

if [ ! -z "$CLOUDFRONT_ID" ]; then
    echo -e "${YELLOW}⚡ CloudFront:${NC} Cache temizlendi (1-2 dakika içinde güncellenecek)"
fi

echo ""
