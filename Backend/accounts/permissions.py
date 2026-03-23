from rest_framework.permissions import BasePermission


class IsCook(BasePermission):
    """Allow access only to users with the 'cook' role."""

    def has_permission(self, request, view):
        return (
            request.user
            and request.user.is_authenticated
            and request.user.role == 'cook'
        )


class IsCustomer(BasePermission):
    """Allow access only to users with the 'customer' role."""

    def has_permission(self, request, view):
        return (
            request.user
            and request.user.is_authenticated
            and request.user.role == 'customer'
        )


class IsAdmin(BasePermission):
    """Allow access only to users with the 'admin' role."""

    def has_permission(self, request, view):
        return (
            request.user
            and request.user.is_authenticated
            and request.user.role == 'admin'
        )


class IsOwnerOrAdmin(BasePermission):
    """
    Object-level permission: allow access if the requesting user owns the
    object (via a ``user`` attribute) or is an admin.
    """

    def has_object_permission(self, request, view, obj):
        if request.user.role == 'admin':
            return True
        # Support objects that have a direct `user` FK as well as objects
        # that *are* the user (e.g. the User model itself).
        if hasattr(obj, 'user'):
            return obj.user == request.user
        return obj == request.user
