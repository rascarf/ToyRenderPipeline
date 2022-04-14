using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class CSMTest : MonoBehaviour
{
    // Start is called before the first frame update

    CSM CSMInstance;

    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        Camera cam = Camera.main;

        Light light = RenderSettings.sun;

        Vector3 LightDir = light.transform.rotation * Vector3.forward;

        if(CSMInstance == null)
        {
            CSMInstance = new CSM();
        }

        CSMInstance.Update(cam,LightDir);
        CSMInstance.DebugDraw();
    }
}
