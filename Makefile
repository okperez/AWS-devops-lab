up:
	docker-compose up --build

down:
	docker-compose down

run:
	cd backend && python app.py

install:
	cd backend && python -m pip install -r requirements.txt
