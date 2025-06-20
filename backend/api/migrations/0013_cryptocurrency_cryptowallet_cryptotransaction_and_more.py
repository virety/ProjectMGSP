# Generated by Django 5.2.3 on 2025-06-13 07:23

import django.db.models.deletion
import uuid
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('api', '0012_alter_forumpost_options_forumpost_comments_count_and_more'),
    ]

    operations = [
        migrations.CreateModel(
            name='CryptoCurrency',
            fields=[
                ('id', models.CharField(help_text='CoinGecko ID (e.g., bitcoin)', max_length=50, primary_key=True, serialize=False)),
                ('symbol', models.CharField(help_text='Symbol (e.g., BTC)', max_length=10, unique=True)),
                ('name', models.CharField(help_text='Full name (e.g., Bitcoin)', max_length=100)),
                ('icon_url', models.URLField(blank=True, help_text='Icon URL from CoinGecko')),
                ('is_active', models.BooleanField(default=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('current_price_usd', models.DecimalField(decimal_places=8, default=0, max_digits=20)),
                ('market_cap', models.BigIntegerField(default=0)),
                ('price_change_24h', models.DecimalField(decimal_places=2, default=0, max_digits=10)),
                ('last_updated', models.DateTimeField(blank=True, null=True)),
            ],
            options={
                'verbose_name': 'Cryptocurrency',
                'verbose_name_plural': 'Cryptocurrencies',
                'ordering': ['symbol'],
            },
        ),
        migrations.CreateModel(
            name='CryptoWallet',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('balance', models.DecimalField(decimal_places=8, default=0, max_digits=20)),
                ('wallet_address', models.CharField(blank=True, help_text='Wallet address (if applicable)', max_length=255)),
                ('is_active', models.BooleanField(default=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('cryptocurrency', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='api.cryptocurrency')),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='crypto_wallets', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'verbose_name': 'Crypto Wallet',
                'verbose_name_plural': 'Crypto Wallets',
                'unique_together': {('user', 'cryptocurrency')},
            },
        ),
        migrations.CreateModel(
            name='CryptoTransaction',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('transaction_type', models.CharField(choices=[('buy', 'Buy'), ('sell', 'Sell'), ('transfer_in', 'Transfer In'), ('transfer_out', 'Transfer Out'), ('exchange', 'Exchange')], max_length=20)),
                ('status', models.CharField(choices=[('pending', 'Pending'), ('completed', 'Completed'), ('failed', 'Failed'), ('cancelled', 'Cancelled')], default='pending', max_length=20)),
                ('crypto_amount', models.DecimalField(decimal_places=8, max_digits=20)),
                ('usd_amount', models.DecimalField(decimal_places=2, max_digits=15)),
                ('fee_amount', models.DecimalField(decimal_places=2, default=0, max_digits=15)),
                ('exchange_rate', models.DecimalField(decimal_places=8, max_digits=20)),
                ('from_address', models.CharField(blank=True, max_length=255)),
                ('to_address', models.CharField(blank=True, max_length=255)),
                ('transaction_hash', models.CharField(blank=True, max_length=255)),
                ('notes', models.TextField(blank=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('completed_at', models.DateTimeField(blank=True, null=True)),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='crypto_transactions', to=settings.AUTH_USER_MODEL)),
                ('wallet', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='transactions', to='api.cryptowallet')),
            ],
            options={
                'verbose_name': 'Crypto Transaction',
                'verbose_name_plural': 'Crypto Transactions',
                'ordering': ['-created_at'],
            },
        ),
        migrations.CreateModel(
            name='CryptoPriceHistory',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('price_usd', models.DecimalField(decimal_places=8, max_digits=20)),
                ('market_cap', models.BigIntegerField()),
                ('volume_24h', models.BigIntegerField(default=0)),
                ('timestamp', models.DateTimeField()),
                ('cryptocurrency', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='price_history', to='api.cryptocurrency')),
            ],
            options={
                'verbose_name': 'Crypto Price History',
                'verbose_name_plural': 'Crypto Price History',
                'ordering': ['-timestamp'],
                'indexes': [models.Index(fields=['cryptocurrency', 'timestamp'], name='api_cryptop_cryptoc_1d03dd_idx')],
            },
        ),
    ]
