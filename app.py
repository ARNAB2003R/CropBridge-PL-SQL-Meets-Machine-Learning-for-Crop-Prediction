from fastapi import FastAPI, Request
from pydantic import BaseModel
import joblib

app = FastAPI()

# Load your model
model = joblib.load("crop_model.pkl")

# Define input schema
class CropInput(BaseModel):
    N: float
    P: float
    K: float
    temperature: float
    humidity: float
    ph: float
    rainfall: float

@app.post("/predict_crop")  # <-- Must be POST!
async def predict_crop(data: CropInput):
    features = [[
        data.N, data.P, data.K,
        data.temperature, data.humidity,
        data.ph, data.rainfall
    ]]
    prediction = model.predict(features)[0]
    return {"recommended_crop": prediction}
