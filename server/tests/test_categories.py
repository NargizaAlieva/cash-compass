from app.services.default_categories import DEFAULT_CATEGORIES


def test_new_user_gets_default_categories(client, auth_headers):
    response = client.get("/categories", headers=auth_headers)
    assert response.status_code == 200
    assert len(response.json()) == len(DEFAULT_CATEGORIES)


def test_filter_categories_by_kind(client, auth_headers):
    income = client.get("/categories?kind=income", headers=auth_headers).json()
    assert len(income) > 0
    assert all(category["kind"] == "income" for category in income)


def test_create_category(client, auth_headers):
    response = client.post(
        "/categories",
        headers=auth_headers,
        json={"name": "Coffee", "kind": "expense", "icon": "local_cafe", "color": "#795548"},
    )
    assert response.status_code == 201
    assert response.json()["name"] == "Coffee"


def test_duplicate_category_name_fails(client, auth_headers):
    # "Food" is one of the default expense categories
    response = client.post(
        "/categories", headers=auth_headers, json={"name": "food", "kind": "expense"}
    )
    assert response.status_code == 409


def test_same_name_allowed_for_other_kind(client, auth_headers):
    response = client.post(
        "/categories", headers=auth_headers, json={"name": "Food", "kind": "income"}
    )
    assert response.status_code == 201


def test_invalid_color_fails(client, auth_headers):
    response = client.post(
        "/categories", headers=auth_headers, json={"name": "Coffee", "color": "brown"}
    )
    assert response.status_code == 422


def test_update_category(client, auth_headers):
    category_id = client.get("/categories", headers=auth_headers).json()[0]["id"]
    response = client.put(
        f"/categories/{category_id}", headers=auth_headers, json={"color": "#000000"}
    )
    assert response.status_code == 200
    assert response.json()["color"] == "#000000"


def test_delete_category(client, auth_headers):
    categories = client.get("/categories", headers=auth_headers).json()
    response = client.delete(f"/categories/{categories[0]['id']}", headers=auth_headers)
    assert response.status_code == 204
    assert len(client.get("/categories", headers=auth_headers).json()) == len(categories) - 1


def test_cannot_touch_other_users_category(client, auth_headers, other_auth_headers):
    category_id = client.get("/categories", headers=auth_headers).json()[0]["id"]
    response = client.delete(f"/categories/{category_id}", headers=other_auth_headers)
    assert response.status_code == 404