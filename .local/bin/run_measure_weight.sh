#!/bin/bash

# Set the project directory and venv path
PROJECT_DIR="/home/chrisq/Code/xiaomi-scale"
VENV_DIR="$PROJECT_DIR/.venv"
REQUIREMENTS_FILE="$PROJECT_DIR/requirements.txt"

# Navigate to the project directory
cd "$PROJECT_DIR" || { echo "Error: Could not enter $PROJECT_DIR"; exit 1; }

# Function to check if the venv is valid
is_venv_valid() {
    [ -f "$VENV_DIR/bin/activate" ] && [ -x "$VENV_DIR/bin/python" ]
}

# Check if a valid virtual environment exists
if is_venv_valid; then
    echo "✅ Virtual environment found, activating..."
else
    echo "⚠ Virtual environment missing or broken. Creating a new one..."
    python3 -m venv "$VENV_DIR" || { echo "Error: Failed to create venv"; exit 1; }
    
    echo "✅ Virtual environment created. Installing dependencies..."
    source "$VENV_DIR/bin/activate"
    pip install --upgrade pip
    [ -f "$REQUIREMENTS_FILE" ] && pip install -r "$REQUIREMENTS_FILE"
fi

# Ensure the correct Python binary is used
PYTHON_BIN="$VENV_DIR/bin/python"

# Run the script as root, explicitly passing the environment
echo "🚀 Running MeasureWeight.py as root..."
sudo env "PATH=$VENV_DIR/bin:$PATH" "$PYTHON_BIN" MeasureWeight.py

