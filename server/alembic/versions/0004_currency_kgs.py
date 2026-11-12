"""accounts in Kyrgyz som

Revision ID: 0004
Revises: 0003
Create Date: 2026-11-13 12:00:00
"""
from typing import Sequence, Union

from alembic import op


revision: str = '0004'
down_revision: Union[str, None] = '0003'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # The app works in Kyrgyz som now; old accounts were created as KZT
    op.execute("UPDATE accounts SET currency = 'KGS' WHERE currency = 'KZT'")


def downgrade() -> None:
    op.execute("UPDATE accounts SET currency = 'KZT' WHERE currency = 'KGS'")
