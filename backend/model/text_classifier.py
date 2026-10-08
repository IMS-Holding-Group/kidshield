import re
import os
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
import joblib

class TextClassifier:
    def __init__(self):
        self.vectorizer = None
        self.model = None
        self.model_path = os.path.join(os.path.dirname(__file__), 'classifier_model.pkl')
        self.vectorizer_path = os.path.join(os.path.dirname(__file__), 'vectorizer.pkl')
        
        # قوائم الكلمات الضارة بالعربية والإنجليزية - محدثة وأدق
        self.toxic_words_ar = {
            'تنمر': ['غبي', 'أحمق', 'فاشل', 'كسول', 'بليد', 'جاهل', 'حقير', 'وضيع', 'نذل', 'خسيس', 'تافه', 'سافل', 'منحط', 'وضيع', 'هبل', 'معتوه'],
            'كراهية': ['كراهية', 'عداء', 'بغض', 'حقد', 'ضغينة', 'كره', 'مقت', 'بغيض', 'مكروه', 'محتقر'],
            'ألفاظ غير لائقة': ['سب', 'شتم', 'لعن', 'قذف', 'شتيمة', 'سباب', 'لعنة', 'زنا', 'فحش', 'بذاءة'],
            'تهديد': ['سأقتلك', 'سأضربك', 'سأؤذيك', 'تهديد', 'ترهيب', 'سأقتل', 'سأضرب', 'أقتلك', 'أذبحك'],
            'تحرش': ['تحرش', 'مضايقة', 'مضايق', 'متحرش', 'تحرش جنسي', 'متحرش'],
            'عنف': ['قتل', 'ضرب', 'عنف', 'إيذاء', 'سفك دم']
        }
        
        self.toxic_words_en = {
            'bullying': ['stupid', 'idiot', 'fool', 'loser', 'dumb', 'moron', 'pathetic', 'trash', 'worthless', 'ugly'],
            'hate': ['hate', 'hated', 'hating', 'despise', 'loathe', 'racist', 'terrorist'],
            'profanity': ['damn', 'hell', 'crap', 'shit', 'fuck', 'ass', 'bitch', 'bastard', 'wtf', 'omg'],
            'threat': ['kill', 'die', 'threat', 'harm', 'hurt', 'murder', 'suicide', 'bomb'],
            'harassment': ['harass', 'harassment', 'molest', 'rape', 'pedophile'],
            'violence': ['violence', 'gore', 'blood', 'weapon']
        }
        
    def preprocess_text(self, text):
        if not isinstance(text, str):
            return ""
        
        text = text.lower()
        text = re.sub(r'http\S+|www\S+|https\S+', '', text, flags=re.MULTILINE)
        text = re.sub(r'\@\w+|\#\w+', '', text)
        text = re.sub(r'[^\w\s]', ' ', text)
        text = re.sub(r'\s+', ' ', text)
        text = text.strip()
        
        return text
        
    def load_model(self):
        if os.path.exists(self.model_path) and os.path.exists(self.vectorizer_path):
            try:
                self.model = joblib.load(self.model_path)
                self.vectorizer = joblib.load(self.vectorizer_path)
                return True
            except Exception as e:
                print(f"خطأ في تحميل النموذج: {str(e)}")
                return False
        return False
    
    def detect_toxic_patterns(self, text):
        text_lower = text.lower().strip()
        # تقسيم النص لفحص كلمات منفردة وتقليل الإيجابيات الخاطئة
        words_set = set(re.findall(r'\b\w+\b', text_lower))
        detected_patterns = []
        
        for category, words in self.toxic_words_ar.items():
            for word in words:
                if word in text_lower or word in words_set:
                    detected_patterns.append(category)
                    break
        
        for category, words in self.toxic_words_en.items():
            for word in words:
                if word in text_lower or word in words_set:
                    detected_patterns.append(category)
                    break
        
        return list(dict.fromkeys(detected_patterns))  # إزالة التكرار مع الحفاظ على الترتيب
    
    def _score_model_rules(self, text, detected_patterns):
        """نموذج 2: قوائم كلمات وأنماط (قواعد) → درجة 0..1"""
        if not detected_patterns:
            return 0.0, 'rules'
        base = 0.25 + min(len(detected_patterns) * 0.15, 0.55)
        high = {'تهديد', 'threat', 'تحرش', 'harassment', 'عنف', 'violence'}
        if set(detected_patterns) & high:
            base = min(1.0, base + 0.2)
        return min(1.0, base), 'rules'

    def _score_model_lexical(self, text):
        """نموذج 3: كثافة تطابق مع قواميس الكلمات (بدون ML)"""
        processed = self.preprocess_text(text)
        if len(processed) < 2:
            return 0.0, 'lexical'
        t = text.lower()
        hit = 0
        for bucket in (self.toxic_words_ar, self.toxic_words_en):
            for cat_words in bucket.values():
                for word in cat_words:
                    if len(word) > 1 and word in t:
                        hit += 1
        words = processed.split()
        n = max(len(words), 1)
        ratio = min(1.0, (hit / n) * 2.2 + hit * 0.07)
        return ratio, 'lexical'

    def _score_model_sklearn(self, text, processed_text, detected_patterns, key_words):
        """نموذج 1: TF-IDF + LogisticRegression"""
        if self.model is None or self.vectorizer is None or len(processed_text) < 3:
            return 0.0, 0.0, 0, 'sklearn'
        text_vectorized = self.vectorizer.transform([processed_text])
        prediction = self.model.predict(text_vectorized)[0]
        probabilities = self.model.predict_proba(text_vectorized)[0]
        confidence = float(max(probabilities))
        if prediction == 1 or detected_patterns:
            k = self._extract_keywords(text, self.vectorizer, self.model)
            key_words.clear()
            key_words.extend(k)
            return confidence, confidence, prediction, 'sklearn'
        return confidence, 0.0, prediction, 'sklearn'

    def predict_ensemble(self, text):
        """
        دمج 3 نماذج: (1) تعلم آلي تقليدي، (2) قوائم كلمات/أنماط، (3) كثافة لغوية.
        تُحسب درجة لكل نموذج ويُختار أعلى مستوى خطورة مع توافق التصنيف.
        """
        if self.model is None or self.vectorizer is None:
            return {
                'label': 'safe',
                'risk_level': 'safe',
                'confidence': 0.0,
                'reason': 'النماذج غير جاهزة',
                'category': 'غير محدد',
                'ensemble': {'note': 'النموذج غير مدرب'},
            }

        try:
            processed_text = self.preprocess_text(text)
            if len(processed_text) < 2:
                return {
                    'label': 'safe',
                    'risk_level': 'safe',
                    'confidence': 0.0,
                    'reason': 'النص قصير جداً',
                    'category': 'غير محدد',
                    'ensemble': {},
                }

            detected_patterns = self.detect_toxic_patterns(text)
            key_words = []
            sk_conf, sk_harm_score, sk_pred, _ = self._score_model_sklearn(
                text, processed_text, detected_patterns, key_words
            )
            r_score, r_name = self._score_model_rules(text, detected_patterns)
            lx_score, lx_name = self._score_model_lexical(text)

            votes = {
                'sklearn_harmful_prob': round(sk_harm_score, 4),
                'rules_score': round(r_score, 4),
                'lexical_score': round(lx_score, 4),
            }

            if not key_words and self.model and self.vectorizer:
                key_words = self._extract_keywords(text, self.vectorizer, self.model)

            combined = max(r_score, lx_score, sk_harm_score if (sk_pred == 1 or detected_patterns) else sk_conf * 0.35)

            if sk_pred == 0 and not detected_patterns and r_score < 0.2 and lx_score < 0.2:
                return {
                    'label': 'safe',
                    'risk_level': 'low',
                    'risk_score': float(combined),
                    'confidence': float(sk_conf),
                    'reason': 'محتوى آمن',
                    'explanation': 'لم يُدمج اكتشاف ضار عبر النماذج الثلاثة.',
                    'category': 'آمن',
                    'patterns': [],
                    'key_words': key_words,
                    'ensemble': {**votes, 'chosen': 'max_conservative', 'models': 3},
                }

            category = self._determine_category(text, detected_patterns)
            reason = self._get_reason(text, category, detected_patterns)
            if sk_pred == 1 and not detected_patterns:
                category = category or 'محتوى ضار'
                reason = reason or 'تصنيف النموذج التعلمي'

            risk_level = self._determine_risk_level(
                max(sk_conf, combined), detected_patterns, category
            )
            if combined >= 0.75 or r_score >= 0.6 or lx_score >= 0.55:
                risk_level = 'high' if risk_level != 'low' else 'medium'
            if combined >= 0.55 and risk_level == 'low':
                risk_level = 'medium'

            risk_score = min(1.0, float(max(combined, sk_harm_score, (r_score + lx_score) / 2)))
            explanation = self._generate_explanation(risk_level, detected_patterns, key_words, category)
            explanation += f" | دمج 3 نماذج: تعلمي {votes['sklearn_harmful_prob']}, قواعد {votes['rules_score']}, لغوي {votes['lexical_score']}"

            return {
                'label': 'harmful' if risk_level in ['medium', 'high'] else 'safe',
                'risk_level': risk_level,
                'risk_score': risk_score,
                'confidence': float(max(sk_conf, combined)),
                'reason': reason,
                'explanation': explanation,
                'category': category,
                'patterns': detected_patterns,
                'key_words': key_words,
                'ensemble': {**votes, 'chosen': 'max_risk', 'models': 3},
            }
        except Exception as e:
            return {
                'label': 'safe',
                'risk_level': 'safe',
                'confidence': 0.0,
                'reason': f'خطأ في التحليل: {str(e)}',
                'category': 'خطأ',
                'ensemble': {'error': str(e)},
            }

    def predict(self, text):
        """للتوافق مع الكود القديم: يفضّل التنبؤ المدمج."""
        return self.predict_ensemble(text)
    
    def _determine_risk_level(self, confidence, patterns, category):
        # حد أقصى لوزن الأنماط
        pattern_weight = min(len(patterns) * 0.18, 0.5)
        confidence_weight = confidence * 0.7
        total_score = confidence_weight + pattern_weight
        
        # أنماط عالية الخطورة ترفع المستوى
        high_risk_patterns = {'تهديد', 'threat', 'تحرش', 'harassment', 'عنف', 'violence'}
        has_high_risk = bool(high_risk_patterns & set(patterns))
        
        if total_score >= 0.7 or len(patterns) >= 3 or (has_high_risk and len(patterns) >= 1):
            return 'high'
        elif total_score >= 0.45 or len(patterns) >= 2:
            return 'medium'
        elif total_score >= 0.25 or len(patterns) >= 1:
            return 'low'
        return 'low'
    
    def _extract_keywords(self, text, vectorizer, model, top_n=5):
        try:
            if self.vectorizer is None or self.model is None:
                return []
            
            processed_text = self.preprocess_text(text)
            words = processed_text.split()
            
            if len(words) < 2:
                return []
            
            text_vectorized = self.vectorizer.transform([processed_text])
            feature_names = self.vectorizer.get_feature_names_out()
            
            coef = self.model.coef_[0]
            feature_scores = text_vectorized.toarray()[0]
            
            word_scores = {}
            for i, word in enumerate(words):
                if word in feature_names:
                    idx = list(feature_names).index(word)
                    score = coef[idx] * feature_scores[idx]
                    if word not in word_scores or abs(score) > abs(word_scores[word]):
                        word_scores[word] = score
            
            sorted_words = sorted(word_scores.items(), key=lambda x: abs(x[1]), reverse=True)
            return [word for word, score in sorted_words[:top_n] if abs(score) > 0.01]
        except:
            return []
    
    def _determine_category(self, text, patterns):
        if not patterns:
            return 'محتوى ضار'
        
        category_map = {
            'تنمر': 'تنمر',
            'bullying': 'تنمر',
            'كراهية': 'كراهية',
            'hate': 'كراهية',
            'ألفاظ غير لائقة': 'ألفاظ غير لائقة',
            'profanity': 'ألفاظ غير لائقة',
            'تهديد': 'تهديد',
            'threat': 'تهديد',
            'تحرش': 'تحرش',
            'harassment': 'تحرش',
            'عنف': 'عنف',
            'violence': 'عنف'
        }
        
        for pattern in patterns:
            if pattern in category_map:
                return category_map[pattern]
        
        return 'محتوى ضار'
    
    def _get_reason(self, text, category, patterns):
        reasons = []
        
        if 'تنمر' in category or 'bullying' in str(patterns):
            reasons.append('تنمر')
        if 'كراهية' in category or 'hate' in str(patterns):
            reasons.append('كراهية')
        if 'ألفاظ غير لائقة' in category or 'profanity' in str(patterns):
            reasons.append('ألفاظ غير لائقة')
        if 'تهديد' in category or 'threat' in str(patterns):
            reasons.append('تهديد')
        if 'تحرش' in category or 'harassment' in str(patterns):
            reasons.append('تحرش')
        if 'عنف' in category or 'violence' in str(patterns):
            reasons.append('عنف')
        
        if reasons:
            return '، '.join(reasons)
        
        return 'محتوى ضار'
    
    def _generate_explanation(self, risk_level, patterns, key_words, category):
        explanations = []
        
        if risk_level == 'high':
            explanations.append('مستوى خطورة عالي')
        elif risk_level == 'medium':
            explanations.append('مستوى خطورة متوسط')
        else:
            explanations.append('مستوى خطورة منخفض')
        
        if patterns:
            explanations.append(f'تم اكتشاف: {", ".join(patterns[:3])}')
        
        if key_words:
            explanations.append(f'كلمات مؤثرة: {", ".join(key_words[:3])}')
        
        if category and category != 'آمن':
            explanations.append(f'الفئة: {category}')
        
        return '. '.join(explanations) if explanations else 'لا يوجد محتوى ضار واضح'
