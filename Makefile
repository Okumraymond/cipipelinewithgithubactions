.PHONY: build test lint

# Build the application
build:
	pyenv global 3.11.9
	pip install -r requirements.txt

# Run tests
test:
	PYTHONPATH=. pytest tests/ -v

# Lint the code
lint:
	flake8 src/ tests/

# Run the application
run:
	python src/app.py
