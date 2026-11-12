from datetime import date

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.goal import Goal
from app.models.user import User
from app.schemas.goal import GoalIn, GoalOut, GoalsOverview, GoalUpdate
from app.services.goals import average_monthly_saving, goal_out

router = APIRouter(prefix="/goals", tags=["goals"])


def get_own_goal(goal_id: int, user: User, db: Session) -> Goal:
    goal = db.get(Goal, goal_id)
    if goal is None or goal.user_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Goal not found")
    return goal


def _out(db: Session, user: User, goal: Goal) -> GoalOut:
    today = date.today()
    return goal_out(goal, average_monthly_saving(db, user.id, today), today)


@router.get("", response_model=GoalsOverview)
def list_goals(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    today = date.today()
    saving = average_monthly_saving(db, current_user.id, today)
    goals = db.scalars(
        select(Goal).where(Goal.user_id == current_user.id).order_by(Goal.id)
    ).all()
    return GoalsOverview(
        monthly_saving=round(saving, 2),
        goals=[goal_out(goal, saving, today) for goal in goals],
    )


@router.post("", response_model=GoalOut, status_code=status.HTTP_201_CREATED)
def create_goal(
    data: GoalIn,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    goal = Goal(user_id=current_user.id, **data.model_dump())
    db.add(goal)
    db.commit()
    db.refresh(goal)
    return _out(db, current_user, goal)


@router.put("/{goal_id}", response_model=GoalOut)
def update_goal(
    goal_id: int,
    data: GoalUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    goal = get_own_goal(goal_id, current_user, db)
    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(goal, field, value)
    db.commit()
    db.refresh(goal)
    return _out(db, current_user, goal)


@router.delete("/{goal_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_goal(
    goal_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    db.delete(get_own_goal(goal_id, current_user, db))
    db.commit()
