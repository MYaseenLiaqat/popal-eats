"""Create or update an admin user (run once). Usage: python scripts/seed_admin.py admin@test.com password"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.core.account_status import ACTIVE
from app.core.roles import ADMIN
from app.core.security import hash_password
from app.database import SessionLocal
from app.models.user import User


def main() -> None:
    if len(sys.argv) < 3:
        print("Usage: python scripts/seed_admin.py <email> <password>")
        sys.exit(1)

    email = sys.argv[1].lower()
    password = sys.argv[2]
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.email == email).first()
        if user:
            user.role = ADMIN
            user.account_status = ACTIVE
            user.password_hash = hash_password(password)
            print(f"Updated existing user to admin: {email}")
        else:
            user = User(
                full_name="Admin",
                first_name="Admin",
                last_name="User",
                email=email,
                password_hash=hash_password(password),
                role=ADMIN,
                account_status=ACTIVE,
                email_verified=True,
            )
            db.add(user)
            print(f"Created admin: {email}")
        db.commit()
    finally:
        db.close()


if __name__ == "__main__":
    main()
