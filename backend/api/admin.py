from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import User, Transaction, Card, Deposit, Loan, Mortgage, Application
from .forms import CustomUserCreationForm, CustomUserChangeForm

class CustomUserAdmin(UserAdmin):
    # The forms to add and change user instances
    form = CustomUserChangeForm
    add_form = CustomUserCreationForm

    # The fields to be used in displaying the User model.
    list_display = ("phone_number", "email", "first_name", "last_name", "is_staff")
    list_filter = ("is_staff", "is_superuser", "is_active", "groups")

    # The fieldsets to be used in editing a user.
    fieldsets = (
        (None, {"fields": ("phone_number", "password")}),
        ("Personal info", {"fields": ("first_name", "last_name", "email", "avatar", "middle_name")}),
        (
            "Permissions",
            {
                "fields": (
                    "is_active",
                    "is_staff",
                    "is_superuser",
                    "groups",
                    "user_permissions",
                ),
            },
        ),
        ("Important dates", {"fields": ("last_login", "date_joined")}),
    )
    
    # The fieldsets to be used in creating a user.
    add_fieldsets = (
        (None, {
            "classes": ("wide",),
            "fields": ("phone_number", "first_name", "last_name", "email", "password", "password2"),
        }),
    )
    
    search_fields = ("phone_number", "first_name", "last_name", "email")
    ordering = ("phone_number",)

class ApplicationAdmin(admin.ModelAdmin):
    list_display = ('user', 'application_type', 'status', 'created_at')
    list_filter = ('status', 'application_type')
    search_fields = ('user__phone_number',)
    readonly_fields = ('user', 'application_type', 'details', 'created_at', 'updated_at')

    def get_queryset(self, request):
        return super().get_queryset(request).select_related('user')

admin.site.register(User, CustomUserAdmin)
admin.site.register(Transaction)
admin.site.register(Card)
admin.site.register(Deposit)
admin.site.register(Loan)
admin.site.register(Mortgage)
admin.site.register(Application, ApplicationAdmin)
