# Heilmeier Draft

## Project Title

Hardware Accelerator for Dense Neural Network Linear Layer (MAC Array Chiplet)

### 1\. What are you trying to do? 

I want to build a small hardware unit that can multiply input values by stored weights and produce output values faster than a normal software program. This operation is used in many AI systems. My goal is to design this hardware, test that it gives correct results, connect it to a host through a standard interface, and compare its performance with a software version.

### 2\. How is it done today, and what are the limits of current practice?

Today, this operation is usually done in software on CPUs or GPUs using general-purpose computing platforms and machine learning libraries. These platforms are flexible, but they are not always the most efficient solution for one repeated operation. They can spend extra time and energy on control overhead, memory movement, and general-purpose features that are not necessary for a single dense neural-network layer. This limits efficiency when the same multiply-and-add pattern is repeated many times.

### 3\. What is new in your approach and why do you think it will be successful?

My approach is to focus on one important operation only: the dense neural-network linear layer. Instead of building a large and complicated AI system, I will design a dedicated hardware accelerator for this one operation. I will also connect it to a host using a standard interface and evaluate it using software profiling, arithmetic intensity, and roofline analysis. I think this will be successful because the design is focused, realistic, and small enough to implement, verify, and synthesize within the course timeline, while still targeting a computation-heavy kernel used in real AI workloads.

