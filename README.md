# 🧠 C# AI Assistant (RAG)

A C# assistant built using a **Retrieval-Augmented Generation (RAG)** pipeline.  
It retrieves relevant knowledge from a database and generates answers using a cloud LLM.

---

## 🚀 Features

- 📊 Data pipeline from Stack Overflow data  
- 🗂️ SQLite database with FTS5 search  
- 🔍 Relevant context retrieval (top-k results)  
- 🧠 Answer generation via Groq (LLaMA 3.1)  
- 📱 Flutter chat interface with streaming responses  

---

## 🏗️ How it works

1. User asks a question  
2. System checks if it’s related to C#  
3. Searches relevant content in SQLite (FTS)  
4. Builds a prompt with context  
5. Generates an answer using LLM  

---

## ⚙️ Setup

```bash
cd data_pipeline
pip install -r requirements.txt
python build_db.py
```

Add your API key:

```
GROQ_API_KEY=your_key
```

Run the app:

```bash
cd flutter_app
flutter pub get
flutter run
```

---

## 📁 Structure

```
data_pipeline/   # build database
flutter_app/     # mobile app
```

---

## 👨‍💻 Author

Sofiane Taleb  
GitHub: https://github.com/softal55  
