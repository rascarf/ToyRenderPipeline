using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraController : MonoBehaviour
{
    Camera camera;
    public GameObject cameraHandle;

    public float Velocity = 100.0f;
    public float VerticalVelocity = 1.0f;
    public float HorizontalVelocity = 1.0f;

    struct FrameInput
    {

        public float Walk;
        public float Stride;
        public float XOffset;
        public float YOffset;
    };
    void Start()
    {
        camera = GetComponent<Camera>();
    }

    FrameInput GatherInput()
    {
        FrameInput CurrentInput = new FrameInput();
        if (Input.GetKey(KeyCode.W))
        {
            CurrentInput.Walk += 1.0f;
        }

        if(Input.GetKey(KeyCode.S))
        {
            CurrentInput.Walk -= 1.0f;
        }

        if(Input.GetKey (KeyCode.D))
        {
            CurrentInput.Stride += 1.0f;
        }

        if(Input.GetKey(KeyCode.A))
        {
            CurrentInput.Stride -= 1.0f;
        }

        CurrentInput.XOffset = Input.GetAxis("Horizontal");
        CurrentInput.YOffset = Input.GetAxis("Vertical");

        return CurrentInput;
    }
    void Update()
    {
        FrameInput CurrentFrameInput = GatherInput();

        camera.transform.Translate(Velocity * Time.deltaTime * Vector3.forward * CurrentFrameInput.Walk);
        camera.transform.Translate(Velocity * Time.deltaTime * Vector3.right * CurrentFrameInput.Stride);

        if(Input.GetMouseButton(0))
        {
            cameraHandle.transform.RotateAround(camera.transform.position, cameraHandle.transform.up,CurrentFrameInput.XOffset * HorizontalVelocity);
            camera.transform.RotateAround(camera.transform.position, camera.transform.right, -CurrentFrameInput.YOffset * HorizontalVelocity);
           
        }
            

        //camera.transform.Rotate(new Vector3(CurrentFrameInput.YOffset, CurrentFrameInput.XOffset, 0), Space.Self);
    }
}
