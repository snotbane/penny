
## Invocation

In Penny, a `label` must be called from the host engine in order to begin execution:

```gd
Penny.start('label_name')
```

Alternatively, if Penny was previously exited using a `rise` or `return` statement, execution may be resumed from where it was last left off, without jumping to a specific label.

```gd
Penny.resume()
```

> [!WARNING] Jumping to Conclusions
> Keep in mind that using `Penny.resume()` at the very end of a script will immediately exit the environment and there may not be any indication of this, so make sure only to call this if you know it's safe to do so.
>
> Neither entering nor exiting the Penny environment will alter its state, but using `Penny.start()` will set the player's position and reset their depth within it.


> [!TIP] Script Length
> Penny scripts can be any length and can even loop infinitely. Best practice is to use one `.pny` file per "scene" (not engine scene, I mean more like a "chapter").

## Termination

Penny will run through its execution until one of several things happens:

- A `return` statement is encountered
- A `rise` statement is encountered at a flow depth of `0`
- The end of the script file is reached (same behavior as `rise`)
- An uncaught exception is thrown

### Concurrency

Multiple Penny scripts can be run simultaneously, but all scripts share the same data. This is to allow for background objects to be scripted (see [this example from Paper Mario TTYD](https://youtu.be/-9R0PpJB9So?t=849)) or for other potential concurrent implementations.

> [!CAUTION] Concurrency Risks
> It is **extremely dangerous** to modify variables, and/or interact with objects, shared between two Penny scripts. These pose similar risks to *multithreaded* code but are not protected as such. **Most** applications will only have **one** script running at a time.
