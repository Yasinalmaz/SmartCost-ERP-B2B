import re
import torch
from transformers import AutoTokenizer, AutoModelForQuestionAnswering

print("🧠 Hugging Face Yapay Zeka Modelleri Yükleniyor... (Lütfen bekleyin, internet hızınıza göre 1-2 dk sürebilir)")

# 1. Hazır fonksiyon yerine AI Modelini ve Kelime Parçalayıcıyı (Tokenizer) manuel olarak indiriyoruz
model_adi = "lserinol/bert-turkish-question-answering"
tokenizer = AutoTokenizer.from_pretrained(model_adi)
model = AutoModelForQuestionAnswering.from_pretrained(model_adi)

print("✅ Tensör (PyTorch) Tabanlı AI Başarıyla Yüklendi!")

# 2. Doğrudan Tensör İşleme Motoru
def yapay_zeka_soru_sor(soru: str, metin: str):
    # Soruyu ve metni yapay zekanın anlayacağı sayılara (tensör matrislerine) çeviriyoruz
    girdiler = tokenizer(soru, metin, return_tensors="pt")
    
    with torch.no_grad():
        ciktilar = model(**girdiler)
        
    # En yüksek olasılıklı cevabın başlangıç ve bitiş koordinatlarını hesapla
    baslangic = ciktilar.start_logits.argmax()
    bitis = ciktilar.end_logits.argmax() + 1
    
    cevap_tokenleri = girdiler.input_ids[0, baslangic:bitis]
    # Bulunan koordinatlardaki sayıları tekrar insan diline (metne) çevir
    return tokenizer.decode(cevap_tokenleri, skip_special_tokens=True)

def metni_analiz_et(metin: str):
    sonuclar = []
    try:
        # 3. Aşama: Gelişmiş PyTorch AI ile Cümle Bağlamını Anlama
        malzeme_cevabi = yapay_zeka_soru_sor("Hangi malzeme isteniyor?", metin)
        miktar_cevabi = yapay_zeka_soru_sor("Kaç adet isteniyor?", metin)
        
        bulunan_malzeme = malzeme_cevabi.title().strip()
        
        # Miktarın içinden sadece rakamları çek
        rakamlar = re.findall(r'\d+', miktar_cevabi)
        adet = int(rakamlar[0]) if rakamlar else 1
        
        # Gereksiz takıları temizle
        gereksizler = ["Adet", "Tane", "Kg", "Metre", "Lt", "Lazım", "Acil", "Istiyorum"]
        for g in gereksizler:
            bulunan_malzeme = bulunan_malzeme.replace(g, "").strip()

        if bulunan_malzeme:
            sonuclar.append({"isim": bulunan_malzeme, "adet": adet})
            
    except Exception as e:
        # 4. Aşama: Hata Tolerans (Fail-Safe) Sistemi
        # Eğer yapay zeka çuvallarsa sistem çökmez, eski kural tabanlı yedeğe geçer
        print(f"⚠️ AI yanıt veremedi ({e}), Kural tabanlı yedek sisteme geçiliyor.")
        kalip = r'(\d+)\s*(?:adet|tane|kg|metre|lt)?\s*([a-zA-ZçğıöşüÇĞİÖŞÜ\s]+)'
        eslesmeler = re.findall(kalip, metin.lower())
        for adet, isim in eslesmeler:
            sonuclar.append({"isim": isim.strip().title(), "adet": int(adet)})

    return sonuclar