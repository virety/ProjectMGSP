from django.db import migrations
from django.contrib.auth import get_user_model
from django.contrib.auth.hashers import make_password

def create_superuser(apps, schema_editor):
    User = get_user_model()
    
    # Проверяем, нет ли уже суперпользователя
    if not User.objects.filter(is_superuser=True).exists():
        User.objects.create(
            phone_number='+79999999999',
            password=make_password('admin123456'),
            first_name='Admin',
            last_name='Nyota',
            email='admin@nyota.com',
            is_staff=True,
            is_superuser=True,
            is_active=True
        )

def reverse_create_superuser(apps, schema_editor):
    User = get_user_model()
    User.objects.filter(phone_number='+79999999999').delete()

class Migration(migrations.Migration):
    
    dependencies = [
        ('api', '0002_alter_card_owner'),
    ]
    
    operations = [
        migrations.RunPython(create_superuser, reverse_create_superuser),
    ] 