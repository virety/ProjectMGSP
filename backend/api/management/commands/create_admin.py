from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from django.conf import settings

User = get_user_model()

class Command(BaseCommand):
    help = 'Create a superuser for admin panel'

    def handle(self, *args, **options):
        phone_number = '+79999999999'  # Телефон админа
        password = 'admin123456'       # Пароль админа
        
        if not User.objects.filter(phone_number=phone_number).exists():
            User.objects.create_superuser(
                phone_number=phone_number,
                password=password,
                first_name='Admin',
                last_name='Nyota',
                email='admin@nyota.com'
            )
            self.stdout.write(
                self.style.SUCCESS(f'Superuser created successfully!')
            )
            self.stdout.write(
                self.style.SUCCESS(f'Phone: {phone_number}')
            )
            self.stdout.write(
                self.style.SUCCESS(f'Password: {password}')
            )
        else:
            self.stdout.write(
                self.style.WARNING('Superuser already exists!')
            ) 