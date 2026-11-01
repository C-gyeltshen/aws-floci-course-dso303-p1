## Step 17 - Practical 2 and Practical 4, compared with both running

### Scaling

| Question | ECS + Application Auto Scaling | Kubernetes + HPA |
| --- | --- | --- |
| What integer is written? | | |
| Who writes it? | | |
| Where does that thing run? | | |
| Where does the metric come from? | | |
| What does "50% CPU" mean - 50% of what? | | |
| How is scale-in slowed down? | | |
| What happens if there is no capacity for the new instance/pod? | | |
| What creates the alarms, if anything? | | |

### Exposure

| Question | ECS + ALB (Lab 05) | Kubernetes + Ingress (Step 16) |
| --- | --- | --- |
| How many AWS objects did I create by hand? | | |
| What is the target type, and why? | | |
| How are targets registered and deregistered? | | |
| How are competing routing rules disambiguated? | | |
| What would I change to move this to another cloud? | | |
| What is the cost of exposing ten services? | | |

### Two paragraphs, in prose

1. If the AWS control plane has a bad afternoon, what happens to each of the two
   scaling arrangements, and which of them can I still debug?

2. For USMS specifically - one small team, one region, quiet for eight months and
   very busy for two - which would I choose, and what is the strongest argument
   AGAINST my own choice?