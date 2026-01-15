// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title ICanonGuardRegistry
 * @notice Interface for the CanonGuardRegistry contract
 * @dev A shared registry for labeling entities (action builders, hubs) associated with CanonGuard instances
 */
interface ICanonGuardRegistry {
  // ~~~ STRUCTS ~~~

  /**
   * @notice Information about a labeled entity
   * @param label The label string (may be client-side encrypted)
   * @param lastEditedAt The timestamp of the last edit
   */
  struct Edition {
    string label;
    uint256 lastEditedAt;
  }

  /**
   * @notice Entity with its label information for batch reads
   * @param entity The entity address
   * @param edition The edition data containing label and timestamp
   */
  struct EntityWithEdition {
    address entity;
    Edition edition;
  }

  // ~~~ EVENTS ~~~

  /**
   * @notice Emitted when an entity is recorded or updated
   * @param _canonGuard The CanonGuard instance
   * @param _entity The entity address being labeled
   * @param _label The label string
   * @param _lastEditedAt The timestamp of the edit
   */
  event EntityRecorded(address indexed _canonGuard, address indexed _entity, string _label, uint256 _lastEditedAt);

  /**
   * @notice Emitted when an entity is removed
   * @param _canonGuard The CanonGuard instance
   * @param _entity The entity address being removed
   */
  event EntityRemoved(address indexed _canonGuard, address indexed _entity);

  // ~~~ ERRORS ~~~

  /**
   * @notice Thrown when the caller is not a signer of the Safe associated with the CanonGuard
   */
  error NotSafeSigner();

  /**
   * @notice Thrown when the entities and labels arrays have different lengths
   */
  error ArrayLengthMismatch();

  /**
   * @notice Thrown when an empty label is provided
   */
  error EmptyLabel();

  /**
   * @notice Thrown when an entity is not found in the registry
   */
  error EntityNotFound();

  // ~~~ MUTATIVE METHODS ~~~

  /**
   * @notice Records or updates labels for multiple entities
   * @dev Can only be called by a signer of the Safe associated with the CanonGuard
   * @param _canonGuard The CanonGuard instance
   * @param _entities Array of entity addresses to label
   * @param _labels Array of labels corresponding to each entity
   */
  function record(address _canonGuard, address[] calldata _entities, string[] calldata _labels) external;

  /**
   * @notice Removes multiple entities from the registry
   * @dev Can only be called by a signer of the Safe associated with the CanonGuard
   * @param _canonGuard The CanonGuard instance
   * @param _entities Array of entity addresses to remove
   */
  function remove(address _canonGuard, address[] calldata _entities) external;

  // ~~~ VIEW METHODS ~~~

  /**
   * @notice Returns the total number of entities registered for a CanonGuard
   * @param _canonGuard The CanonGuard instance
   * @return _total The total count of entities
   */
  function totalEntities(address _canonGuard) external view returns (uint256 _total);

  /**
   * @notice Returns a paginated list of entities and their labels for a CanonGuard
   * @param _canonGuard The CanonGuard instance
   * @param _offset The starting index for pagination
   * @param _limit The maximum number of entities to return
   * @return _entities Array of entities with their edition data
   */
  function read(
    address _canonGuard,
    uint256 _offset,
    uint256 _limit
  ) external view returns (EntityWithEdition[] memory _entities);

  /**
   * @notice Returns the label edition for a specific entity
   * @param _canonGuard The CanonGuard instance
   * @param _entity The entity address
   * @return _edition The edition data for the entity
   */
  function entityLabel(address _canonGuard, address _entity) external view returns (Edition memory _edition);
}
