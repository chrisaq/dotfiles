from __future__ import annotations
from datetime import datetime, timezone
from typing import Literal, Any
from pydantic import BaseModel, Field, ConfigDict

State = Literal['ok', 'pending', 'warning', 'error', 'unknown', 'disabled']
PRIORITY = {'disabled':0, 'ok':1, 'pending':2, 'unknown':3, 'warning':4, 'error':5}

def now():
    return datetime.now(timezone.utc).timestamp()

class Action(BaseModel):
    id: str
    label: str
    safe: bool = False
    reason: str = ''

class Result(BaseModel):
    model_config = ConfigDict(extra='forbid')
    schema_version: Literal[1] = 1
    id: str
    state: State
    summary: str
    details: list[str] = Field(default_factory=list)
    metrics: dict[str, Any] = Field(default_factory=dict)
    actions: list[Action] = Field(default_factory=list)
    checked_at: float = Field(default_factory=now)
    last_success: float | None = None
    activity: str = ''
    stale: bool = False

class Check(BaseModel):
    model_config = ConfigDict(extra='forbid')
    provider: str
    enabled: bool = True
    interval: int = Field(default=60, ge=10)
    timeout: int = Field(default=30, ge=1, le=3600)
    options: dict[str, Any] = Field(default_factory=dict)

class SetupItem(BaseModel):
    model_config = ConfigDict(extra='forbid')
    provider: str
    enabled: bool = True
    waybar: bool = False
    options: dict[str, Any] = Field(default_factory=dict)

class Settings(BaseModel):
    model_config = ConfigDict(extra='forbid')
    theme: Literal['macchiato', 'latte'] = 'macchiato'
    terminal: list[str] = Field(default_factory=lambda:['ghostty', '-e'])
    menu: list[str] = Field(default_factory=lambda:['rofi', '-dmenu', '-i', '-p', 'Maintenance'])
    waybar_signal: int = Field(default=12, ge=1, le=20)
    max_workers: int = Field(default=4, ge=1, le=8)
    checks: dict[str, Check] = Field(default_factory=dict)
    setup: dict[str, SetupItem] = Field(default_factory=dict)
