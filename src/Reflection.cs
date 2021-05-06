using System;
using System.Reflection;

namespace PSAccessToken
{
    internal class Reflection
    {
        public static FieldInfo GetField(Type type, string name, BindingFlags flags)
        {
            return type.GetField(name, flags) ?? throw new NotSupportedException(
                String.Format("Failed to get field {0} on {1}", name, type.Name));
        }

        public static T GetFieldValue<T>(FieldInfo field, object? obj)
        {
            return (T)field.GetValue(obj) ?? throw new NullReferenceException(
                String.Format("Field {0} returned unexpected null value", field.Name));
        }

        public static MethodInfo GetMethod(Type type, string name, BindingFlags flags, Type[] types)
        {
            return type.GetMethod(name, flags, null, types, null) ?? throw new NotSupportedException(
                String.Format("Failed to get method {0} on {1}", name, type.Name));
        }

        public static T InvokeMethod<T>(MethodInfo method, object? obj, object?[]? parameters)
        {
            return (T)method.Invoke(obj, parameters) ?? throw new NullReferenceException(
                String.Format("Method {0} return unexpected null value", method.Name));
        }

        public static PropertyInfo GetProperty(Type type, string name, BindingFlags flags)
        {
            return type.GetProperty(name, flags) ?? throw new NotSupportedException(
                String.Format("Failed to get property {0} on {1}", name, type.Name));
        }

        public static T GetPropertyValue<T>(PropertyInfo property, object? obj)
        {
            return (T)property.GetValue(obj) ?? throw new NullReferenceException(
                String.Format("Property {0} returned unexpected null value", property.Name));
        }
    }
}
