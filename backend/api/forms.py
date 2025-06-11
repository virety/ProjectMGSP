from django import forms
from django.contrib.auth.forms import ReadOnlyPasswordHashField
from .models import User

class CustomUserCreationForm(forms.ModelForm):
    """
    A form for creating new users. Includes all the required
    fields, plus a repeated password.
    """
    password = forms.CharField(label='Password', widget=forms.PasswordInput)
    password2 = forms.CharField(label='Password confirmation', widget=forms.PasswordInput)

    class Meta:
        model = User
        fields = ('phone_number', 'first_name', 'last_name', 'email')

    def clean_password2(self):
        # Check that the two password entries match
        password = self.cleaned_data.get("password")
        password2 = self.cleaned_data.get("password2")
        if password and password2 and password != password2:
            raise forms.ValidationError("Passwords don't match")
        return password2

    def save(self, commit=True):
        # Save the provided password in hashed format
        user = super().save(commit=False)
        user.set_password(self.cleaned_data["password"])
        if commit:
            user.save()
        return user


class CustomUserChangeForm(forms.ModelForm):
    """A form for updating users. Includes all the fields on
    the user, but replaces the password field with admin's
    password hash display field.
    """
    password = ReadOnlyPasswordHashField(
        label="Password",
        help_text=(
            "Raw passwords are not stored, so there is no way to see this "
            "user's password, but you can change the password "
            'using <a href="../password/">this form</a>.'
        ),
    )

    class Meta:
        model = User
        fields = ('phone_number', 'email', 'first_name', 'last_name', 'is_active', 'is_staff', 'is_superuser') 