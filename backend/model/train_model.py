import pandas as pd
import os
import re
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split, cross_val_score, GridSearchCV
from sklearn.metrics import classification_report, confusion_matrix, accuracy_score, precision_score, recall_score, f1_score
from sklearn.pipeline import Pipeline
import joblib

def preprocess_text(text):
    if not isinstance(text, str):
        return ""
    
    text = text.lower()
    text = re.sub(r'http\S+|www\S+|https\S+', '', text, flags=re.MULTILINE)
    text = re.sub(r'\@\w+|\#\w+', '', text)
    text = re.sub(r'[^\w\s]', ' ', text)
    text = re.sub(r'\s+', ' ', text)
    text = text.strip()
    
    return text

def train_model():
    dataset_path = os.path.join(os.path.dirname(__file__), '..', '..', 'data', 'jigsaw_toxic_train.csv')
    
    if not os.path.exists(dataset_path):
        print(f"الملف غير موجود: {dataset_path}")
        return False
    
    try:
        print("جاري تحميل البيانات...")
        df = pd.read_csv(dataset_path)
        print(f"تم تحميل {len(df)} سجل")
        
        if 'comment_text' not in df.columns:
            print("العمود 'comment_text' غير موجود في البيانات")
            return False
        
        toxic_columns = ['toxic', 'severe_toxic', 'obscene', 'threat', 'insult', 'identity_hate']
        available_columns = [col for col in toxic_columns if col in df.columns]
        
        if not available_columns:
            print("لا توجد أعمدة سمية في البيانات")
            return False
        
        df['is_toxic'] = df[available_columns].max(axis=1)
        
        print("جاري معالجة النصوص...")
        df['processed_text'] = df['comment_text'].fillna('').astype(str).apply(preprocess_text)
        
        df = df[df['processed_text'].str.len() > 3]
        
        texts = df['processed_text'].values
        labels = df['is_toxic'].astype(int).values
        
        print(f"عدد النصوص الآمنة: {np.sum(labels == 0)}")
        print(f"عدد النصوص الضارة: {np.sum(labels == 1)}")
        
        print("جاري إنشاء TF-IDF Vectorizer...")
        vectorizer = TfidfVectorizer(
            max_features=10000,
            ngram_range=(1, 3),
            min_df=2,
            max_df=0.95,
            sublinear_tf=True,
            stop_words='english'
        )
        
        print("جاري تحويل النصوص إلى متجهات...")
        X = vectorizer.fit_transform(texts)
        y = labels
        
        print("جاري تقسيم البيانات...")
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=0.2, random_state=42, stratify=y
        )
        
        print("جاري تدريب النموذج...")
        model = LogisticRegression(
            max_iter=2000,
            random_state=42,
            C=1.0,
            penalty='l2',
            solver='lbfgs',
            class_weight='balanced',
            n_jobs=-1
        )
        
        print("جاري التدريب...")
        model.fit(X_train, y_train)
        
        print("جاري تقييم النموذج...")
        y_pred = model.predict(X_test)
        
        accuracy = accuracy_score(y_test, y_pred)
        precision = precision_score(y_test, y_pred, zero_division=0)
        recall = recall_score(y_test, y_pred, zero_division=0)
        f1 = f1_score(y_test, y_pred, zero_division=0)
        
        print("\n" + "="*50)
        print("نتائج التدريب:")
        print("="*50)
        print(f"الدقة (Accuracy): {accuracy:.4f}")
        print(f"الدقة (Precision): {precision:.4f}")
        print(f"الاستدعاء (Recall): {recall:.4f}")
        print(f"F1 Score: {f1:.4f}")
        print("="*50)
        
        print("\nتقرير التصنيف:")
        print(classification_report(y_test, y_pred, target_names=['آمن', 'ضار']))
        
        print("\nمصفوفة الارتباك:")
        print(confusion_matrix(y_test, y_pred))
        
        print("\nجاري التحقق المتقاطع...")
        cv_scores = cross_val_score(model, X_train, y_train, cv=5, scoring='f1')
        print(f"متوسط F1 Score (5-fold CV): {cv_scores.mean():.4f} (+/- {cv_scores.std() * 2:.4f})")
        
        model_dir = os.path.dirname(__file__)
        model_path = os.path.join(model_dir, 'classifier_model.pkl')
        vectorizer_path = os.path.join(model_dir, 'vectorizer.pkl')
        
        print("\nجاري حفظ النموذج...")
        joblib.dump(model, model_path)
        joblib.dump(vectorizer, vectorizer_path)
        
        print(f"\nتم حفظ النموذج في: {model_path}")
        print(f"تم حفظ Vectorizer في: {vectorizer_path}")
        print("\n✅ تم تدريب النموذج بنجاح!")
        
        return True
        
    except Exception as e:
        print(f"❌ خطأ في التدريب: {str(e)}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == '__main__':
    train_model()
