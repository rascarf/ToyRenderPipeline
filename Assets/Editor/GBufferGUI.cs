using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
public class GBufferGUI : ShaderGUI
{
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        base.OnGUI(materialEditor, properties);
        GUILayout.Label("Hello");
    }
}
