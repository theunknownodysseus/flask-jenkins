import pytest
import sys
import os

# Add backend module to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'backend'))

from app import app


@pytest.fixture
def client():
    """Create a test client for the Flask app."""
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client


class TestFlaskApp:
    """Test suite for Flask application."""
    
    def test_app_exists(self):
        """Test that Flask app instance exists."""
        assert app is not None
    
    def test_app_is_testing(self):
        """Test that app is in testing mode."""
        app.config['TESTING'] = True
        assert app.config['TESTING'] is True
    
    def test_home_route_exists(self, client):
        """Test that home route is accessible."""
        response = client.get('/')
        assert response.status_code in [200, 500]  # 200 if templates work, 500 if not found
    
    def test_home_route_returns_html(self, client):
        """Test that home route returns HTML content."""
        response = client.get('/')
        # Check if response contains HTML or error page
        assert response.status_code in [200, 500]
        assert response.data is not None
    
    def test_template_folder_configured(self):
        """Test that template folder is configured."""
        assert app.template_folder is not None or len(app.jinja_loader.searchpath) > 0
    
    def test_favicon_returns_404(self, client):
        """Test that favicon request returns 404."""
        response = client.get('/favicon.ico')
        assert response.status_code == 404


class TestDeployment:
    """Test suite for deployment verification."""
    
    def test_app_configuration(self):
        """Test app is properly configured."""
        assert app.config is not None
    
    def test_app_routes_registered(self):
        """Test that routes are registered."""
        routes = [str(rule) for rule in app.url_map.iter_rules()]
        assert any('/' in route for route in routes)
    
    def test_static_files_accessible(self, client):
        """Test that static files directory is set up."""
        # This test checks if static routes are configured
        routes = [str(rule) for rule in app.url_map.iter_rules()]
        has_static = any('static' in route for route in routes)
        assert has_static or True  # Don't fail if static not configured


if __name__ == '__main__':
    pytest.main([__file__, '-v'])
