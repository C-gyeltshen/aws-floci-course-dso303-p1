# Independent Lab Exercises
## Exercise 1: Create a new IAM user
* Create a new IAM group `usms-qa`. 
    ```bash 
    aws iam create-group --group-name usms-qa
    ```
* Tag the user with `Key=Role,Value=QA` and `Key=Project`,`Value=USMS`.
    ```bash 
    QA_ARN=$(aws iam create-user \
    --user-name usms-qa-01 \
    --tags Key=Role,Value=QA Key=Project,Value=USMS \
    --query 'User.Arn' --output text)
    echo "$QA_ARN"
    ```

* Add user `usms-qa-01` inside it.
    ```bash
    aws iam add-user-to-group --group-name usms-qa --user-name usms-qa-01
    ```
* Attach the existing `USMSDeveloperBase` policy to the group — do not create a new policy.
    ```bash
    aws iam attach-group-policy \
    --group-name usms-qa \
    --policy-arn arn:aws:iam::000000000000:policy/USMSDeveloperBase
    ```
