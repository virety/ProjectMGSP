# Generated by Django 5.2.3 on 2025-06-13 06:26

import django.db.models.deletion
import uuid
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('api', '0010_card_is_active'),
    ]

    operations = [
        migrations.CreateModel(
            name='AIChat',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('title', models.CharField(blank=True, max_length=255)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('is_active', models.BooleanField(default=True)),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='ai_chats', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'verbose_name': 'AI Chat',
                'verbose_name_plural': 'AI Chats',
                'ordering': ['-updated_at'],
            },
        ),
        migrations.CreateModel(
            name='AIChatMessage',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('role', models.CharField(choices=[('user', 'User'), ('assistant', 'Assistant'), ('system', 'System')], max_length=10)),
                ('content', models.TextField()),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('tokens_used', models.IntegerField(blank=True, null=True)),
                ('model_used', models.CharField(blank=True, max_length=50)),
                ('processing_time', models.FloatField(blank=True, null=True)),
                ('chat', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='messages', to='api.aichat')),
            ],
            options={
                'verbose_name': 'AI Chat Message',
                'verbose_name_plural': 'AI Chat Messages',
                'ordering': ['created_at'],
            },
        ),
        migrations.CreateModel(
            name='PredictionPost',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('currency_pair', models.CharField(help_text='e.g., USD/RUB', max_length=10)),
                ('prediction_text', models.TextField()),
                ('direction', models.CharField(choices=[('up', 'Up'), ('down', 'Down')], max_length=4)),
                ('confidence', models.IntegerField(help_text='Confidence level 1-100')),
                ('target_date', models.DateField(blank=True, null=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('likes_count', models.IntegerField(default=0)),
                ('comments_count', models.IntegerField(default=0)),
                ('author', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='prediction_posts', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'verbose_name': 'Prediction Post',
                'verbose_name_plural': 'Prediction Posts',
                'ordering': ['-created_at'],
            },
        ),
        migrations.CreateModel(
            name='PredictionComment',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('content', models.TextField()),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('author', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='prediction_comments', to=settings.AUTH_USER_MODEL)),
                ('post', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='comments', to='api.predictionpost')),
            ],
            options={
                'verbose_name': 'Prediction Comment',
                'verbose_name_plural': 'Prediction Comments',
                'ordering': ['created_at'],
            },
        ),
        migrations.CreateModel(
            name='PredictionLike',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='prediction_likes', to=settings.AUTH_USER_MODEL)),
                ('post', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='likes', to='api.predictionpost')),
            ],
            options={
                'verbose_name': 'Prediction Like',
                'verbose_name_plural': 'Prediction Likes',
                'unique_together': {('user', 'post')},
            },
        ),
    ]
