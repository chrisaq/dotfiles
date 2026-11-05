from typing import Any, Literal
from pydantic import BaseModel, Field
from ..model import now, SetupItem as SetupItem


class Observation(BaseModel):
    id: str
    status: Literal[
        "ready", "required", "blocked", "unavailable", "disabled", "unsupported"
    ]
    summary: str
    details: list[str] = Field(default_factory=list)
    checked_at: float = Field(default_factory=now)


class Step(BaseModel):
    id: str
    kind: str
    title: str
    requires: list[str] = Field(default_factory=list)
    options: dict[str, Any] = Field(default_factory=dict)


class Plan(BaseModel):
    id: str
    action: str = "apply"
    steps: list[Step] = Field(default_factory=list)
    blockers: list[str] = Field(default_factory=list)
    changes: list[str] = Field(default_factory=list)
    fingerprints: dict[str, str | None] = Field(default_factory=dict)
    settings_hash: str = ""
