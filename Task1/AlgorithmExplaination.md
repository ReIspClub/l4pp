# **RC4 Algorithm Explaination**

#### _Author: Bui Quoc Lap (l4pp)_

## State 1: Preparation (Key Scheduling Algorithm)

From `array S = [0,1,2,3,....255]` and `key` (decided by user)
For each `s[i]`:
```python 
- j = (j + s[i] + key[i % keyLen]) % 256
- swap s[i], s[j]
```
After these step, we have an unique array for each key used.


## State 2: Make plain no longer plain (Pseudo-Random Generated Algorithm) 

Start with `i = 0, j = 0`. <br>
For each characters of plaintext (which will become cipher):

``` python
- i = i + 1
- j = (j + s[i]) % 256
- swap (s[i], s[j])
- t = (s[i] + s[j]) % 256
- keyStreamByte = s[t]
- cipherByte = plaintextByte ^ keyStreamByte
```
> _Mod 256 operations make sure that the result still in range of len(s)._

## _DECRYPTION_

Since `XOR` operation can be reversed by itself. If you have the same key used in encryption, you can get the plaintext from ciphertext by following steps:

```python
- Genarate s = [0,1,2,3,...255]
- Use given key to modify s same as in encryption.
- Do the same as encryption but in final step: 
plaintextByte = cipherByte ^ keyStreamByte 
```