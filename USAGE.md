# Triskele usage
**NOTE:** Triskele is still very new and can be very unstable. Save often, and make backups.

## Nodes
### Dialog Node
The Dialog node is the main node type, and what most of your dialog tree will consist of. It contains text to be displayed by the game.

![Dialog node](Images/DialogNode.png)

Clicking the label in the center pulls up a larger dialog editor, which you can use to write your text.

![Dialog node text editor](Images/DialogNodeTextEditor.png)

> Note: Multilanguage support is planned for the future, but as of right now, Triskele only supports English.

### Expression Node
The Expression node contains a line of code to be run by the game.

![Expression node](Images/ExpressionNode.png)

### Options Node
The Options node represents a list of options that the user can choose from. Options are added and removed via the +/- buttons at the top of the node.

![Options node](Images/OptionsNode.png)

If "Use Conditions" is checked, then a Condition box is added to the left of each option. These are expressions, which must return booleans. If the expression is false, the option is disabled and cannot be selected by players. If the Condition box is left empty, then the option is always choosable.

![Options node with conditions](Images/OptionsNodeWithConditions.png)

### Condition
The Condition node has an expression of its own, which must return a boolean. It then progresses to either True or False depending on the result.

![Condition node](Images/ConditionNode.png)