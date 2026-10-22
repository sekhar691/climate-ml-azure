from fastapi.testclient import TestClient
from main import app

def test_predict():
    with TestClient(app) as client:
        assert client.get('/health').json()['model_loaded']
        result=client.post('/predict',json={'temperature_c':24,'humidity_pct':85,'pressure_hpa':1004,'wind_kmh':18})
        assert result.status_code == 200
        data=result.json()
        assert 0 <= data['rain_probability'] <= 1
        assert data['prediction'] in ('rain','no_rain')

def test_validation():
    with TestClient(app) as client:
        assert client.post('/predict',json={'temperature_c':24,'humidity_pct':150,'pressure_hpa':1004,'wind_kmh':18}).status_code == 422
