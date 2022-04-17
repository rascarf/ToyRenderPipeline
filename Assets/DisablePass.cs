using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DisablePass : MonoBehaviour
{
    public Material material;
    void Start()
    {
        
        material.SetShaderPassEnabled("Motion Vector",false);
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
