#!/usr/bin/env python3
"""
ML/AI Development Starter Script
Quick verification that all tools work
"""

def test_ml_stack():
    """Test that core ML libraries are working"""
    try:
        import pandas as pd
        import numpy as np
        import sklearn
        import duckdb
        print("✅ Core data science stack: OK")
        
        # Test database connections
        import pymysql
        import psycopg2
        print("✅ Database connectors: OK")
        
        # Test ML frameworks
        import torch
        import transformers
        print("✅ ML frameworks: OK")
        
        # Test OCR
        import pytesseract
        import cv2
        print("✅ OCR tools: OK")
        
        print("\n🚀 ML/AI environment is ready!")
        print("Run 'jupyter' to start Jupyter Lab")
        print("Run 'streamlit run app.py' for Streamlit apps")
        
    except ImportError as e:
        print(f"❌ Missing dependency: {e}")

if __name__ == "__main__":
    test_ml_stack() 