# Makefile
SHELL := /usr/bin/env bash

ROOT_DIR := $(shell pwd)
BACKEND_DIR ?= $(ROOT_DIR)/backend
FRONTEND_DIR ?= $(ROOT_DIR)/frontend
BACKEND_PORT ?= 8000
FRONTEND_PORT ?= 8080
ENV_FILE ?= $(BACKEND_DIR)/.env
EMULATOR_ID ?= Medium_Phone_API_36.0

.PHONY: help install api web build-web serve-web android qr kill-ports ip

help:
	@echo "Targets:"
	@echo "  make install     - poetry install (backend) + flutter pub get (frontend)"
	@echo "  make api         - avvia FastAPI (uvicorn) su 0.0.0.0:$(BACKEND_PORT)"
	@echo "  make web         - avvia Flutter Web su 0.0.0.0:$(FRONTEND_PORT)"
	@echo "  make build-web   - flutter build web"
	@echo "  make serve-web   - serve statico della build su :$(FRONTEND_PORT)"
	@echo "  make android     - avvia emulatore Android e l'app"
	@echo "  make qr          - genera QR http://$$(hostname -I | awk '{print $$1}'):$(FRONTEND_PORT)"
	@echo "  make kill-ports  - libera le porte $(BACKEND_PORT) e $(FRONTEND_PORT)"
	@echo "  make ip          - stampa IP locale"

install:
	cd "$(BACKEND_DIR)" && poetry install
	cd "$(FRONTEND_DIR)" && flutter pub get

api:
	cd "$(BACKEND_DIR)" && poetry run uvicorn app.main:app --host 0.0.0.0 --port "$(BACKEND_PORT)" --env-file "$(ENV_FILE)" --reload

web:
	cd "$(FRONTEND_DIR)" && flutter config --enable-web >/dev/null || true
	cd "$(FRONTEND_DIR)" && flutter run -d web-server --web-hostname=0.0.0.0 --web-port="$(FRONTEND_PORT)"

build-web:
	cd "$(FRONTEND_DIR)" && flutter build web

serve-web:
	cd "$(FRONTEND_DIR)/build/web" && python3 -m http.server "$(FRONTEND_PORT)" --bind 0.0.0.0

android:
	cd "$(FRONTEND_DIR)" && flutter emulators --launch "$(EMULATOR_ID)" || true
	cd "$(FRONTEND_DIR)" && flutter run

qr:
	@command -v qrencode >/dev/null 2>&1 || { echo "qrencode non installato"; exit 1; }
	@IP=$$(hostname -I | awk '{print $$1}'); \
	qrencode -o "$(ROOT_DIR)/qrcode.png" "http://$$IP:$(FRONTEND_PORT)"; \
	echo "QR generato: $(ROOT_DIR)/qrcode.png  → http://$$IP:$(FRONTEND_PORT)"

kill-ports:
	-@lsof -ti :$(BACK
