#if UNITY_EDITOR
using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using Sirenix.OdinInspector;
using Sirenix.OdinInspector.Editor;
using Sirenix.OdinInspector.Editor.ActionResolvers;
using Sirenix.OdinInspector.Editor.Drawers;
using Sirenix.OdinInspector.Editor.ValueResolvers;
using Sirenix.Utilities;
using Sirenix.Utilities.Editor;
using UnityEditor;
using UnityEngine;
using UnityEngine.Profiling;
using Object = UnityEngine.Object;

public class FillInFieldAttribute : Attribute
{
    /// <summary> Fill in this field</summary>
    public string fieldName;
}

public class DropMethodRepeater
{
    public static bool isDirty = true;
    private class FilteredPropertyChildren
    {
        public InspectorProperty Property;
        public PropertyChildren Children;
        public PropertySearchFilter SearchFilter;
        private List<InspectorProperty> FilteredChildren;
        public bool IsCurrentlyFiltered => FilteredChildren != null;
        public int Count => FilteredChildren == null ? Children.Count : FilteredChildren.Count;

        public InspectorProperty this[int index] =>
            FilteredChildren == null ? Children[index] : FilteredChildren[index];
    }

    private class ListDrawerConfigInfo
    {
        public ICollectionResolver CollectionResolver;
        public IOrderedCollectionResolver OrderedCollectionResolver;
        public bool IsEmpty;
        public ListDrawerSettingsAttribute CustomListDrawerOptions;
        public int Count;
        public int StartIndex;
        public int EndIndex;
        public DropZoneHandle DropZone;
        public Vector2 DraggingMousePosition;
        public Vector2 DropZoneTopLeft;
        public int InsertAt;
        public int RemoveAt;
        public object[] RemoveValues;
        public bool ShowAllWhilePaging;
        public ObjectPicker ObjectPicker;
        public bool JumpToNextPageOnAdd;
        public GeneralDrawerConfig ListConfig;
        public InspectorProperty Property;
        public GUIContent Label;
        public bool IsAboutToDroppingUnityObjects;
        public bool IsDroppingUnityObjects;
        public bool HideAddButton;
        public bool HideRemoveButton;
        public FilteredPropertyChildren FilteredChildren;
        public bool BaseDraggable;
        public bool BaseIsReadOnly;
        public string SearchFieldControlName = "CollectionSearchFilter_" + Guid.NewGuid().ToString();
        public ActionResolver OnTitleBarGUI;
        public ActionResolver GetCustomAddFunctionVoid;
        public ValueResolver GetCustomAddFunction;
        public ActionResolver CustomRemoveIndexFunction;
        public ActionResolver CustomRemoveElementFunction;
        public ActionResolver OnBeginListElementGUI;
        public ActionResolver OnEndListElementGUI;
        public ValueResolver<Color> ElementColor;
        public Func<object, InspectorProperty, object> GetListElementLabelText;

        public GUIStyle ListItemStyle = new GUIStyle(GUIStyle.none)
        {
            padding = new RectOffset(25, 20, 3, 3)
        };

        public bool IsReadOnly => BaseIsReadOnly || FilteredChildren.IsCurrentlyFiltered;
        public bool Draggable => BaseDraggable && !FilteredChildren.IsCurrentlyFiltered;

        public int NumberOfItemsPerPage => !CustomListDrawerOptions.NumberOfItemsPerPageHasValue
            ? ListConfig.NumberOfItemsPrPage
            : CustomListDrawerOptions.NumberOfItemsPerPage;
    }
    
    public static void SetDirty()
    {
        isDirty = true;
    }
    private static Object[] HandleUnityObjectsDrop(ListDrawerConfigInfo info)
    {
        if (info.IsReadOnly)
            return null;
        EventType type = Event.current.type;
        if (type == EventType.Layout)
            info.IsAboutToDroppingUnityObjects = false;
        if ((type == EventType.DragUpdated || type == EventType.DragPerform) &&
                info.DropZone.Rect.Contains(Event.current.mousePosition))
        {
            Object[] objectArray = null;
            if (DragAndDrop.objectReferences.Any(n => n != null && info.CollectionResolver.ElementType.IsInstanceOfType(n)))
                objectArray = DragAndDrop.objectReferences
                    .Where(x => x != null && info.CollectionResolver.ElementType.IsInstanceOfType(x)).Reverse().ToArray();
            else if (info.CollectionResolver.ElementType.InheritsFrom(typeof(Component)))
                objectArray = DragAndDrop.objectReferences.OfType<GameObject>()
                    .Select(x => x.GetComponent(info.CollectionResolver.ElementType)).Where(x => x != null).Reverse().ToArray();
            else if (info.CollectionResolver.ElementType.InheritsFrom(typeof(Sprite)) &&
                             DragAndDrop.objectReferences.Any(n => n is Texture2D && AssetDatabase.Contains(n)))
                objectArray = DragAndDrop.objectReferences.OfType<Texture2D>()
                    .Select(x => AssetDatabase.LoadAssetAtPath<Sprite>(AssetDatabase.GetAssetPath(x))).Where(x => x != null)
                    .Reverse().ToArray();
            
            //-------------Custom----------------
            if (objectArray == null)
            {
                var elementType = info.CollectionResolver.ElementType;
                var elementTypeAttributes = elementType.GetAttribute<FillInFieldAttribute>();
                if (elementTypeAttributes != null && string.IsNullOrEmpty(elementTypeAttributes.fieldName) == false)
                {
                    var fieldInfo = elementType.GetField(elementTypeAttributes.fieldName);
                    if (fieldInfo != null && DragAndDrop.objectReferences.Any(n => n != null && n is GameObject))
                    {
                        if (info.InsertAt == -1)
                            info.InsertAt = info.FilteredChildren.Count;
                        
                        DragAndDrop.visualMode = DragAndDropVisualMode.Copy;
                        Event.current.Use();
                        info.IsAboutToDroppingUnityObjects = true;
                        info.IsDroppingUnityObjects = info.IsAboutToDroppingUnityObjects;
                        if (type == EventType.DragPerform)
                        {
                            var arr = DragAndDrop.objectReferences.Where(n => n != null && n is GameObject).Reverse().ToArray();
                            var objectArray2 = new object[arr.Length];
                            for (var index = 0; index < arr.Length; index++)
                            {
                                var o = arr[index];
                                var instance = Activator.CreateInstance(elementType);
                                fieldInfo.SetValue(instance, o);
                                objectArray2[index] = instance;
                            }
                            foreach (var @object in objectArray2)
                            {
                                object[] values = new object[info.Property.Tree.WeakTargets.Count];
                                for (int index = 0; index < values.Length; ++index)
                                    values[index] = @object;
                                info.OrderedCollectionResolver.QueueInsertAt(Mathf.Clamp(info.InsertAt, 0, info.FilteredChildren.Count), values);
                            }

                            DropMethodRepeater.SetDirty();
                            DragAndDrop.AcceptDrag();
                            return null;
                        }
                    }
                }
            }
            //-----------------------------
            
            if (objectArray != null && (uint) objectArray.Length > 0U)
            {
                DragAndDrop.visualMode = DragAndDropVisualMode.Copy;
                Event.current.Use();
                info.IsAboutToDroppingUnityObjects = true;
                info.IsDroppingUnityObjects = info.IsAboutToDroppingUnityObjects;
                if (type == EventType.DragPerform)
                {
                    DragAndDrop.AcceptDrag();
                    return objectArray;
                }
            }
        }

        if (type == EventType.Repaint)
            info.IsDroppingUnityObjects = info.IsAboutToDroppingUnityObjects;
        return null;
    }
}

public class InstanceCollectionDrawerMethod<T> where T : class
{
    public void Install()
    {
        Type typeA = typeof(CollectionDrawer<T>);
        Type typeB = typeof(DropMethodRepeater);
        MethodInfo miAFunc = typeA.GetMethod("HandleUnityObjectsDrop",BindingFlags.Static    | BindingFlags.NonPublic);
        MethodInfo miBReplace = typeB.GetMethod("HandleUnityObjectsDrop",BindingFlags.Static | BindingFlags.NonPublic);
        MethodHook hooker = new MethodHook(miAFunc, miBReplace, null);
        hooker.Install();
    }
}


#endif