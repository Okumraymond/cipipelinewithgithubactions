.PHONY: build test lint

# Build the application
build:
	pip install -r requirements.txt

# Run tests
test:
	pytest tests/ -v

# Lint the code
lint:
	flake8 src/ tests/

# Run the application
run:
	python src/app.py
